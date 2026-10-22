-- SCORE_PROBE v3.4 - autonomous passive scoreboard observer.
-- No commands, no joypad, no assertion of validated menu/result addresses.
-- Gameplay signature is provisional; results are candidates, not confirmed goals.
local root=assert(_G.ISSD_PROJECT_ROOT,"Launch via main.lua / SCORE_PROBE")
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance,"BizHawk APIs unavailable")
local dir=root.."/csv/"
local session=os.date("!%Y%m%dT%H%M%SZ")
local ENTER_FRAMES=10
local STABLE_FRAMES=90
local COPY_WAIT_FRAMES=1200
local POST_EXIT_FRAMES=1200
local MAX_GAME_FRAMES=7200
local addr={time=0x01CF3,bonus=0x01CF8,total=0x01CFA,copy=0x0DC06}
local function byte(a)
 local ok,v=pcall(memory.read_u8,a,"WRAM")
 if ok and type(v)=="number" then return v end
 return nil
end
local function word(a)
 local lo,hi=byte(a),byte(a+1)
 if lo==nil or hi==nil then return nil end
 return lo+hi*256
end
local function sample()
 local gs,ptr=word(0x00BA),word(0x1ACC)
 local remaining=byte(0x006B4)
 local s={frame=emu.framecount(),gs=gs,ptr=ptr,remaining=remaining,
  time=byte(addr.time),bonus=word(addr.bonus),total=word(addr.total),copy=word(addr.copy)}
 s.gameplay=(s.gs==0 and s.ptr==0x0F00)
 s.valid=(s.time~=nil and s.bonus~=nil and s.total~=nil)
 s.coherent=s.valid and s.total==s.time+s.bonus
 return s
end
local function key(s)
 if not s.valid then return "unreadable" end
 return table.concat({s.time,s.bonus,s.total},":")
end
-- SCORE_PROBE output control: COMPACT (2 files) by default; FULL preserves v3.4.
-- Independent from DRIBBLE's dribble_csv_mode.txt.
local function csv_mode()
 local f=io.open(root.."/score_csv_mode.txt","rb")
 if not f then return "COMPACT" end
 local raw=f:read("*a") or "";f:close()
 if raw:sub(1,3)=="\239\187\191" then raw=raw:sub(4) end
 local mode=raw:match("^%s*([%a]+)") or ""
 mode=mode:upper()
 assert(mode=="COMPACT" or mode=="FULL","score_csv_mode.txt: use COMPACT or FULL")
 return mode
end
local output_mode=csv_mode()
local function quote(v)
 local x=v==nil and "" or tostring(v)
 return '"'..x:gsub('"','""')..'"'
end
local function append(path,header,fields)
 local f=io.open(path,"rb");local empty=true
 if f then empty=(f:seek("end") or 0)==0;f:close() end
 f=assert(io.open(path,"ab"))
 if empty then assert(f:write(header.."\n")) end
 assert(f:write(table.concat(fields,",").."\n"))
 assert(f:close())
end
local function csv(name,header,values)
 local n=select(2,header:gsub(",",""))+1
 local data={}
 for i=1,n do data[i]=values[i]==nil and "" or tostring(values[i]) end
 if output_mode=="FULL" or name=="score_auto_trials_v34.csv" then
  append(dir..name,header,data)
  return
 end
 -- Detailed source rows remain reversible. CSV escaping protects embedded commas.
 append(dir.."score_diagnostics_v1.csv",
  "session,source_csv,source_columns,source_values",
  {quote(session),quote(name),quote(header),quote(table.concat(data,","))})
end
print("[score_probe] CSV mode="..output_mode..
 (output_mode=="COMPACT" and " (trials + diagnostics)" or " (five legacy reports)"))
local function event(id,s,kind,note)
 csv("score_events_v34.csv","session,id,frame,event,gs,ptr,remaining,time_score,bonus_score,total_score,copy_total,coherent,note",
  {session,id or "",s.frame,kind,s.gs or "",s.ptr or "",s.remaining or "",
   s.time or "",s.bonus or "",s.total or "",s.copy or "",s.coherent and 1 or 0,note or ""})
end
local Detector=require("challenge.dribble_result_detector")
local detector=Detector.new()
local function observe(s)
 local events=Detector.step(detector,s)
 for _,e in ipairs(events) do
  local a=e.trial
  local id=a and (session.."_"..a.id) or ""
  if e.type=="gameplay_start_candidate" then
   event(id,s,e.type,"context_unverified")
  elseif e.type=="primary_change" then
   csv("score_auto_transitions_v34.csv",
    "session,id,frame,phase,old_primary,new_primary,copy_total,gs,ptr,remaining",
    {session,id,s.frame,e.extra.phase,e.extra.previous,e.extra.current,s.copy or "",s.gs or "",s.ptr or "",s.remaining or ""})
  elseif e.type=="early_result_candidate" then
   local p=a.preliminary
   event(id,s,e.type,p.verdict)
   csv("score_early_results_v34.csv",
    "session,id,exit_frame,early_frame,latency_frames,time_score,bonus_score,total_score,copy_at_early,arithmetic_ok,fresh_post_exit,verdict",
    {session,id,a.exited,p.frame,p.frame-a.exited,p.time,p.bonus,p.total,s.copy or "",1,1,p.verdict})
  elseif e.type=="late_copy_correlated" then
   event(id,s,e.type,"supplementary_only")
   csv("score_copy_evidence_v34.csv","session,id,early_frame,copy_match_frame,lag_frames,total_score,copy_total",
    {session,id,a.preliminary.frame,s.frame,s.frame-a.preliminary.frame,a.preliminary.total,s.copy})
  elseif e.type=="trial_closed" then
   local p=a.preliminary
   csv("score_auto_trials_v34.csv",
    "session,id,start_frame,fifth_flag_frame,exit_frame,early_frame,end_frame,time_score,bonus_score,total_score,copy_total,early_verdict,copy_match,copy_match_frame,final_verdict,finish_reason",
    {session,id,a.start,a.first_zero or "",a.exited or "",p and p.frame or "",s.frame,p and p.time or "",
      p and p.bonus or "",p and p.total or "",s.copy or "",p and p.verdict or "",
      a.copy_confirmed_frame and 1 or 0,a.copy_confirmed_frame or "",e.extra.verdict,e.extra.reason})
   event(id,s,e.type,e.extra.verdict)
  elseif e.type~="primary_change" then
   event(id,s,e.type,"hypothesis_only")
  end
 end
end
print("[score_probe] v3.4 AUTOMATIC read-only; WRAM score + provisional gameplay context; session="..session)
print("[score_probe] no commands required; reports in "..dir)
while true do
 observe(sample())
 emu.frameadvance()
end
