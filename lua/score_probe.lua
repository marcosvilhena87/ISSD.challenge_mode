-- SCORE_PROBE v3.1 - temporal cross-validation of DRIBBLE scoreboard hypotheses.
-- Passive WRAM readings only. All markers are operator supplied, not screen detection.
local root=assert(_G.ISSD_PROJECT_ROOT,"Run through main.lua / SCORE_PROBE")
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance,"BizHawk APIs unavailable")
local session=os.date("!%Y%m%dT%H%M%SZ")
local path=root.."/score_probe_commands_v31.txt"
local out=root.."/csv/"
local tracked={}
local seen={}
local function add(a,kind,target,source)
 local key=string.format("%05X/%s/%s",a,kind,target)
 if not seen[key] then seen[key]=true;tracked[#tracked+1]={a=a,kind=kind,target=target,source=source} end
end
-- The operator's principal hypotheses are always tracked, even without v1 output.
add(0x01CF3,"u8","TIME_SCORE","manual")
add(0x01CF8,"u16le","BONUS_SCORE","manual")
add(0x01CFA,"u16le","TOTAL_SCORE","manual")
add(0x0DC06,"u16le","TOTAL_SCORE","manual")
local f=io.open(out.."score_candidates_v1.csv","rb")
if f then
 local head=f:read("*l")
 for line in f:lines() do
  local _,a,kind,target=line:match("^([^,]*),([^,]*),([^,]*),([^,]*)")
  local addr=tonumber(a or "")
  if addr and kind and (target=="TIME_SCORE" or target=="BONUS_SCORE" or target=="TOTAL_SCORE") then add(addr,kind,target,"v1") end
 end
 f:close()
end
local function decode(c)
 local ok,x=pcall(memory.read_u8,c.a,"WRAM")
 if not ok or type(x)~="number" then return nil end
 if c.kind=="u8" then return x end
 if c.kind=="bcd8" then local h,l=math.floor(x/16),x%16;return h<=9 and l<=9 and h*10+l or nil end
 if c.a>=0x1FFFF then return nil end
 local pass,y=pcall(memory.read_u8,c.a+1,"WRAM")
 if not pass or type(y)~="number" then return nil end
 if c.kind=="u16le" then return x+256*y end
 if c.kind=="u16be" then return x*256+y end
 if c.kind=="bcd16le" or c.kind=="bcd16be" then
  if c.kind=="bcd16be" then x,y=y,x end
  local a,b,d,e=x%16,math.floor(x/16),y%16,math.floor(y/16)
  if a>9 or b>9 or d>9 or e>9 then return nil end
  return a+b*10+d*100+e*1000
 end
 return nil
end
local function write(name,header,values)
 local file=io.open(out..name,"rb");local empty=true
 if file then empty=(file:seek("end")==0);file:close() end
 file=assert(io.open(out..name,"ab"))
 if empty then file:write(header.."\n") end
 file:write(table.concat(values,",").."\n");file:close()
end
local active=nil
local completed={}
local used={}
local phase_order={"GAMEPLAY","TRANSITION","RECORD"}
local function category(t,b) return b>0 and "BONUS_POSITIVE" or (t>0 and "TIME_ONLY" or "ZERO") end
local function validid(s) return s and s:match("^[%w_-]+$") end
local function snapshot()
 local result={}
 for i,c in ipairs(tracked) do result[i]=decode(c) end
 return result
end
local function mark(label)
 if not active then print("[score_probe] no active trial");return end
 local expected=phase_order[active.phase+1]
 if label~=expected then
  print("[score_probe] rejected marker "..label.."; expected "..tostring(expected))
  return
 end
 local frame=emu.framecount()
 if frame<active.last_marker_frame then print("[score_probe] non-monotonic marker");return end
 active.phase=active.phase+1
 active.last_marker_frame=frame
 active.markers[label]=frame
 if label=="RECORD" then active.record_values=snapshot() end
 write("score_markers_v31.csv","session,id,frame,marker",{session,active.id,frame,label})
 print("[score_probe] marker "..label.." frame="..frame)
end
local function export_validation()
 local classes={}
 for _,s in ipairs(completed) do classes[s.category]=true end
 local complete=classes.BONUS_POSITIVE and classes.TIME_ONLY and classes.ZERO
 for i,c in ipairs(tracked) do
  local exact,binary,valid,positives,zeros=0,0,0,0,0
  local observations={}
  for _,s in ipairs(completed) do
   local expected=c.target=="BONUS_SCORE" and s.bonus or (c.target=="TIME_SCORE" and s.time or s.time+s.bonus)
   if expected>0 then positives=positives+1 else zeros=zeros+1 end
   local v=s.values[i]
   if v~=nil then
    valid=valid+1
    if v==expected then exact=exact+1 end
    if (v>0)==(expected>0) then binary=binary+1 end
   end
   observations[#observations+1]=s.id..":"..tostring(v==nil and "NA" or v)
  end
  local status="insufficient_controls"
  if complete then
   if valid==#completed and exact==#completed then status="exact_candidate"
   elseif valid==#completed and binary==#completed then status="binary_candidate"
   else status="rejected_by_controls" end
  end
  write("score_validation_v31.csv",
   "session,address_hex,encoding,target,source,trials,positive_controls,zero_controls,exact_matches,binary_matches,valid_reads,status,record_values",
   {session,string.format("0x%05X",c.a),c.kind,c.target,c.source,#completed,positives,zeros,exact,binary,valid,status,'"'..table.concat(observations,";")..'"'})
 end
 print("[score_probe] validation written; complete_controls="..tostring(not not complete).." trials="..#completed)
end
local function finish(t,b)
 if not active then print("[score_probe] no active trial");return end
 if active.phase~=3 or not active.record_values then
  print("[score_probe] rejected RESULT; require GAMEPLAY -> TRANSITION -> RECORD first")
  return
 end
 local frame=emu.framecount()
 local values=active.record_values -- frozen at RECORD marker, never sampled at RESULT
 local kind=category(t,b)
 for i,c in ipairs(tracked) do
  local v=values[i]
  local expected=c.target=="BONUS_SCORE" and b or (c.target=="TIME_SCORE" and t or t+b)
  local status=v==nil and "unreadable" or (v==expected and "exact_candidate" or
   ((v>0)==(expected>0) and "binary_candidate" or "contradicted"))
  write("score_temporal_summary_v31.csv",
   "session,id,category,time_score,bonus_score,address_hex,encoding,target,source,start_frame,first_change,last_change,change_count,record_marker_frame,final_frame,record_value,expected,status",
   {session,active.id,kind,t,b,string.format("0x%05X",c.a),c.kind,c.target,c.source,active.start,
    active.first_change[i] or "",active.last_change[i] or "",active.changes[i] or 0,active.markers.RECORD,frame,
    v==nil and "" or v,expected,status})
 end
 write("score_trials_v31.csv",
  "session,id,start_frame,end_frame,time_score,bonus_score,category,marker_gameplay,marker_transition,marker_record",
  {session,active.id,active.start,frame,t,b,kind,active.markers.GAMEPLAY,active.markers.TRANSITION,active.markers.RECORD})
 completed[#completed+1]={id=active.id,time=t,bonus=b,category=kind,values=values}
 print("[score_probe] completed "..active.id.." category="..kind)
 active=nil
end
local function command(line)
 line=line:match("^%s*(.-)%s*$")
 local id=line:match("^START:([%w_-]+)$")
 if id then
  if active then print("[score_probe] finish or ABORT current trial first");return end
  if used[id] then print("[score_probe] trial ID already used: "..id);return end
  used[id]=true
  active={id=id,start=emu.framecount(),previous=snapshot(),changes={},first_change={},last_change={},markers={},phase=0,last_marker_frame=emu.framecount()}
  print("[score_probe] tracking "..id.." frame="..active.start)
  return
 end
 local label=line:match("^MARK:([%u_]+)$")
 if label then
  if label=="GAMEPLAY" or label=="TRANSITION" or label=="RECORD" then mark(label)
  else print("[score_probe] invalid marker "..label) end
  return
 end
 local cid,t,b=line:match("^RESULT:([%w_-]+):(%d+):(%d+)$")
 if cid then
  if not active or cid~=active.id then print("[score_probe] result ID mismatch");return end
  finish(tonumber(t),tonumber(b));return
 end
 if line=="EXPORT" then export_validation();return end
 if line=="ABORT" then active=nil;print("[score_probe] trial aborted");return end
 if line~="" then print("[score_probe] unknown command: "..line) end
end
local cursor=0
local function poll()
 local file=io.open(path,"rb");if not file then return end
 local size=file:seek("end") or 0
 if size<cursor then cursor=0 end
 file:seek("set",cursor)
 local chunk=file:read("*a") or "";file:close()
 local complete=chunk:match("^(.*\n)")
 if complete then
  cursor=cursor+#complete
  for line in complete:gmatch("([^\n]*)\n") do command(line:gsub("\r$","")) end
 end
end
local commandfile=io.open(path,"rb")
if commandfile then cursor=commandfile:seek("end") or 0;commandfile:close() end
print("[score_probe] v3.1 ready candidates="..#tracked.." command="..path)
while true do
 poll()
 if active then
  local now=snapshot();local frame=emu.framecount()
  for i,c in ipairs(tracked) do
   local old=active.previous[i];local new=now[i]
   if old~=new then
    active.changes[i]=(active.changes[i] or 0)+1
    active.first_change[i]=active.first_change[i] or frame
    active.last_change[i]=frame
    write("score_transitions_v31.csv","session,id,frame,address_hex,encoding,target,source,old_value,new_value",
     {session,active.id,frame,string.format("0x%05X",c.a),c.kind,c.target,c.source,old or "",new or ""})
   end
  end
  active.previous=now
 end
 emu.frameadvance()
end
