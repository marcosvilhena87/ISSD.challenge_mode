-- SCORE_PROBE v2: cross-validation on independently observed YOUR RECORD screens.
-- Read-only; candidates from v1 are hypotheses and never promoted automatically.
local root=assert(_G.ISSD_PROJECT_ROOT,"Launch via main.lua / SCORE_PROBE")
assert(memory and memory.read_u8 and emu and emu.frameadvance and emu.framecount,"BizHawk WRAM API required")
local command=root.."/score_probe_commands_v2.txt"
local csv=root.."/csv/"
local session=os.date("!%Y%m%dT%H%M%SZ")
local function csvrows(path)
 local f=io.open(path,"rb");if not f then return nil end
 local lines={};for line in f:lines() do lines[#lines+1]=line:gsub("\r$","") end;f:close()
 local header=lines[1];if not header then return {} end
 local names={};for v in (header..","):gmatch("(.-),") do names[#names+1]=v end
 local out={}
 for i=2,#lines do
  local fields={};for v in (lines[i]..","):gmatch("(.-),") do fields[#fields+1]=v end
  local row={};for j,key in ipairs(names) do row[key]=fields[j] end
  if row.address_hex then out[#out+1]=row end
 end
 return out
end
local candidates=csvrows(csv.."score_candidates_v1.csv")
assert(candidates and #candidates>0,"Missing csv/score_candidates_v1.csv; run v1 first")
local unique,items={},{}
for _,row in ipairs(candidates) do
 local addr=tonumber(row.address_hex);local encoding=row.encoding
 if addr and encoding then
  local key=string.format("%05X:%s:%s",addr,encoding,row.target or "")
  if not unique[key] then unique[key]=true;items[#items+1]={address=addr,encoding=encoding,target=row.target or "",match=row.match_type or ""} end
 end
end
-- Operator-supplied unsigned 16-bit WRAM candidates (little-endian).
-- Kept even if absent from SCORE_PROBE v1; hypotheses only.
local manual={
 {address=0x01CF3,encoding="u8",target="TIME_SCORE",match="manual_byte_candidate"},
 {address=0x01CF8,encoding="u16le",target="BONUS_SCORE",match="manual_word_candidate"},
 {address=0x01CFA,encoding="u16le",target="TOTAL_SCORE",match="manual_word_candidate"},
 {address=0x0DC06,encoding="u16le",target="TOTAL_SCORE",match="manual_word_candidate"}
}
for _,c in ipairs(manual) do
 local key=string.format("%05X:%s:%s",c.address,c.encoding,c.target)
 if not unique[key] then
  unique[key]=true
  items[#items+1]=c
 else
  for _,existing in ipairs(items) do
   if existing.address==c.address and existing.encoding==c.encoding and existing.target==c.target then
    existing.match=c.match
    break
   end
  end
 end
end
local labels={}
local captures={}
local cursor=0
local function decode(addr,kind)
 local b=memory.read_u8(addr,"WRAM")
 if kind=="u8" then return b end
 if kind=="bcd8" then
  local a,c=math.floor(b/16),b%16
  return a<=9 and c<=9 and a*10+c or nil
 end
 if addr>=0x1FFFF then return nil end
 local b2=memory.read_u8(addr+1,"WRAM")
 if kind=="u16le" then return b+256*b2 end
 if kind=="u16be" then return 256*b+b2 end
 if kind=="bcd16le" or kind=="bcd16be" then
  local lo,hi=b,b2
  if kind=="bcd16be" then lo,hi=b2,b end
  local a,c,d,e=lo%16,math.floor(lo/16),hi%16,math.floor(hi/16)
  if a>9 or c>9 or d>9 or e>9 then return nil end
  return a+10*c+100*d+1000*e
 end
 return nil
end
local function append(path,head,rows)
 local f=io.open(path,"rb");local empty=true
 if f then empty=(f:seek("end") or 0)==0;f:close() end
 local out=assert(io.open(path,"ab"))
 if empty then out:write(head.."\n") end
 for _,r in ipairs(rows) do out:write(table.concat(r,",").."\n") end
 out:close()
end
local function capture(id,t,b)
 if id=="" or id:find("[^%w_-]") then print("[score_probe] invalid id");return end
 if labels[id] then print("[score_probe] duplicate id rejected: "..id);return end
 if #captures>=32 then print("[score_probe] limit: 32 captures");return end
 local values={}
 for i,c in ipairs(items) do values[i]=decode(c.address,c.encoding) end
 labels[id]=true
 captures[#captures+1]={id=id,time=t,bonus=b,frame=emu.framecount(),values=values}
 append(csv.."score_captures_v2.csv","session,id,frame,time_score,bonus_score,total_score,category,candidates",{
 {session,id,emu.framecount(),t,b,t+b,b>0 and "BONUS_POSITIVE" or (t>0 and "TIME_ONLY" or "ZERO"),#items}})
 print("[score_probe] captured "..id.." scores="..t.."/"..b.." frame="..emu.framecount())
end
local function report()
 if #captures<3 then print("[score_probe] need at least three captures");return end
 local classes={}
 for _,s in ipairs(captures) do classes[s.bonus>0 and "BOTH" or (s.time>0 and "TIME_ONLY" or "ZERO")]=true end
 local enough=classes.BOTH and classes.TIME_ONLY and classes.ZERO
 local out={}
 for i,c in ipairs(items) do
  local exact=0;local binary=0;local valid=0;local positives=0;local negatives=0
  local observed={}
  for _,s in ipairs(captures) do
   local v=s.values[i]
   local expected=c.target=="BONUS_SCORE" and s.bonus or (c.target=="TIME_SCORE" and s.time or s.time+s.bonus)
   local expectedPos=expected>0
   if expectedPos then positives=positives+1 else negatives=negatives+1 end
   if v~=nil then
    valid=valid+1
    if v==expected then exact=exact+1 end
    if (v>0)==expectedPos then binary=binary+1 end
   end
   observed[#observed+1]=s.id..":"..tostring(v or "NA")
  end
  local status="insufficient_controls"
  if enough then
   if valid==#captures and exact==#captures then status="exact_candidate"
   elseif valid==#captures and binary==#captures then status="binary_candidate"
   else status="rejected_by_controls" end
  end
  out[#out+1]={session,string.format("0x%05X",c.address),c.encoding,c.target,c.match,
   #captures,positives,negatives,exact,binary,valid,status,'"'..table.concat(observed,";")..'"'}
 end
 append(csv.."score_validation_v2.csv",
 "session,address_hex,encoding,target,v1_match,captures,expected_positive,expected_zero,exact_matches,binary_matches,valid_reads,status,observations",out)
 print("[score_probe] validation exported; complete category controls="..tostring(not not enough).." candidates="..#items)
 print("[score_probe] Results remain hypotheses until reproduced in another session.")
end
local function action(line)
 local id,t,b=line:match("^CAPTURE:([%w_-]+):(%d+):(%d+)$")
 if id then capture(id,tonumber(t),tonumber(b))
 elseif line=="EXPORT" then report()
 elseif line~="" then print("[score_probe] expected CAPTURE:ID:TIME:BONUS or EXPORT; got "..line) end
end
local f=io.open(command,"rb")
if f then cursor=f:seek("end") or 0;f:close() end
print("[score_probe] v2 + manually tracked score candidates loaded "..#items.." candidate interpretations; commands="..command)
while true do
 local file=io.open(command,"rb")
 if file then
  local size=file:seek("end") or 0
  if size<cursor then cursor=0 end
  file:seek("set",cursor)
  local chunk=file:read("*a") or "";file:close()
  local complete=chunk:match("^(.*\n)")
  if complete then
   cursor=cursor+#complete
   for line in complete:gmatch("([^\n]*)\n") do action(line:gsub("\r$","")) end
  end
 end
 emu.frameadvance()
end
