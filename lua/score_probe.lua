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
local function csv(name,header,v)
 local path=dir..name
 local f=io.open(path,"rb");local empty=true
 if f then empty=(f:seek("end") or 0)==0;f:close() end
 f=assert(io.open(path,"ab"))
 if empty then f:write(header.."\n") end
 for i,x in ipairs(v) do if x==nil then v[i]="" end end
 f:write(table.concat(v,",").."\n");f:close()
end
local function event(id,s,kind,note)
 csv("score_events_v34.csv","session,id,frame,event,gs,ptr,remaining,time_score,bonus_score,total_score,copy_total,coherent,note",
  {session,id or "",s.frame,kind,s.gs or "",s.ptr or "",s.remaining or "",
   s.time or "",s.bonus or "",s.total or "",s.copy or "",s.coherent and 1 or 0,note or ""})
end
local previous=nil
local active=nil
local next_id=0
local consecutive=0
local old_gameplay=false
local post_exit_suppress=false
local function start(s)
 next_id=next_id+1
 local id=session.."_"..next_id
 active={id=id,start=s.frame,start_value=key(s),initial_time=s.time,
  initial_bonus=s.bonus,initial_total=s.total,first_zero=nil,flags=0,
  exited=nil,changes=0,first_change=nil,last_change=nil,
  latest_key=key(s),stable_since=s.frame,post_exit_changes=0,main_changed_post_exit=false,preliminary=nil,copy_confirmed_frame=nil}
 event(id,s,"gameplay_start_candidate","context_unverified")
 print("[score_probe] gameplay candidate "..id.." at frame "..s.frame)
end
local function preliminary(s)
 local a=active
 if not a or a.preliminary or not a.exited then return end
 if not s.valid or not s.coherent or not a.first_zero or not a.main_changed_post_exit then return end
 if s.frame-a.stable_since<STABLE_FRAMES then return end
 local verdict=s.bonus>0 and "positive_bonus_candidate" or
  (s.time>0 and "time_only_candidate" or "zero_score_candidate")
 a.preliminary={frame=s.frame,time=s.time,bonus=s.bonus,total=s.total,verdict=verdict}
 event(a.id,s,"early_result_candidate",verdict)
 csv("score_early_results_v34.csv",
 "session,id,exit_frame,early_frame,latency_frames,time_score,bonus_score,total_score,copy_at_early,arithmetic_ok,fresh_post_exit,verdict",
 {session,a.id,a.exited,s.frame,s.frame-a.exited,s.time,s.bonus,s.total,s.copy or "",1,1,verdict})
 print("[score_probe] early "..a.id.." "..verdict.." frame="..s.frame)
end
local function endtrial(s,reason)
 local a=active
 if not a then return end
 local e=a.preliminary
 local copy_ok=e and s.copy~=nil and s.copy==e.total
 local verdict=not a.exited and "gameplay_interrupted" or
  (not a.first_zero and "five_flags_unobserved" or
  (not e and "no_stable_fresh_primary_result" or
  (copy_ok and "copy_correlated_candidate" or "copy_unverified")))
 csv("score_auto_trials_v34.csv",
 "session,id,start_frame,fifth_flag_frame,exit_frame,early_frame,end_frame,time_score,bonus_score,total_score,copy_total,early_verdict,copy_match,copy_match_frame,final_verdict,finish_reason",
 {session,a.id,a.start,a.first_zero or "",a.exited or "",e and e.frame or "",s.frame,
 e and e.time or "",e and e.bonus or "",e and e.total or "",s.copy or "",
 e and e.verdict or "",copy_ok and 1 or 0,a.copy_confirmed_frame or "",verdict,reason})
 event(a.id,s,"trial_closed",verdict)
 active=nil;post_exit_suppress=true
 print("[score_probe] "..a.id.." "..verdict.." "..reason)
end
local function observe(s)
 local in_game=s.gameplay
 if in_game then consecutive=consecutive+1 else consecutive=0 end
 if not active and not post_exit_suppress and consecutive==ENTER_FRAMES and s.remaining==5 then start(s) end
 if active then
  local a=active
  local k=key(s)
  if k~=a.latest_key then
   local prior=a.latest_key
   a.latest_key=k;a.stable_since=s.frame;a.changes=a.changes+1
   a.first_change=a.first_change or s.frame;a.last_change=s.frame
   if a.exited then a.post_exit_changes=a.post_exit_changes+1;a.main_changed_post_exit=true end
   csv("score_auto_transitions_v34.csv","session,id,frame,phase,old_primary,new_primary,copy_total,gs,ptr,remaining",
    {session,a.id,s.frame,a.exited and "POST_EXIT" or "GAMEPLAY",prior,k,s.copy or "",s.gs or "",s.ptr or "",s.remaining or ""})
   if a.preliminary then
    event(a.id,s,"early_candidate_superseded","primary_changed_again")
    a.preliminary=nil;a.copy_confirmed_frame=nil
   end
  end
  if in_game and s.remaining==0 and not a.first_zero then
   a.first_zero=s.frame;event(a.id,s,"fifth_flag_candidate","remaining_0")
  end
  if not in_game and not a.exited then
   a.exited=s.frame;event(a.id,s,"gameplay_exit_candidate","record_screen_unverified")
  end
  preliminary(s)
  if a.preliminary and not a.copy_confirmed_frame and s.copy~=nil and s.copy==a.preliminary.total then
   a.copy_confirmed_frame=s.frame
   event(a.id,s,"late_copy_correlated","supplementary_only")
   csv("score_copy_evidence_v34.csv","session,id,early_frame,copy_match_frame,lag_frames,total_score,copy_total",
    {session,a.id,a.preliminary.frame,s.frame,s.frame-a.preliminary.frame,a.preliminary.total,s.copy})
  end
  if not a.exited then
   if s.frame-a.start>MAX_GAME_FRAMES then endtrial(s,"gameplay_timeout") end
  else
   local age=s.frame-a.exited
   if a.preliminary and a.copy_confirmed_frame then endtrial(s,"copy_correlation_observed")
   elseif age>=COPY_WAIT_FRAMES then endtrial(s,"post_exit_timeout")
   elseif in_game and consecutive>=ENTER_FRAMES then endtrial(s,"new_game_before_resolution") end
  end
 end
 if post_exit_suppress and not in_game then post_exit_suppress=false end
end
print("[score_probe] v3.4 AUTOMATIC read-only; WRAM score + provisional gameplay context; session="..session)
print("[score_probe] no commands required; reports in "..dir)
while true do
 observe(sample())
 emu.frameadvance()
end
