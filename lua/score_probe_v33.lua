-- SCORE_PROBE v3.3 - autonomous passive scoreboard observer.
-- No commands, no joypad, no assertion of validated menu/result addresses.
-- Gameplay signature is provisional; results are candidates, not confirmed goals.
local root=assert(_G.ISSD_PROJECT_ROOT,"Launch via main.lua / SCORE_PROBE")
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance,"BizHawk APIs unavailable")
local dir=root.."/csv/"
local session=os.date("!%Y%m%dT%H%M%SZ")
local ENTER_FRAMES=10
local STABLE_FRAMES=90
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
 s.valid=(s.time~=nil and s.bonus~=nil and s.total~=nil and s.copy~=nil)
 s.coherent=s.valid and s.total==s.time+s.bonus
 return s
end
local function key(s)
 if not s.valid then return "unreadable" end
 return table.concat({s.time,s.bonus,s.total,s.copy},":")
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
 csv("score_events_v33.csv","session,id,frame,event,gs,ptr,remaining,time_score,bonus_score,total_score,copy_total,coherent,note",
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
  latest_key=key(s),stable_since=s.frame,post_exit_changes=0}
 event(id,s,"gameplay_start_candidate","context_unverified")
 print("[score_probe] gameplay candidate "..id.." at frame "..s.frame)
end
local function endtrial(s,reason)
 local a=active
 if not a then return end
 local stable=s.frame-a.stable_since>=STABLE_FRAMES
 local fresh=(a.changes>0 and a.last_change~=nil)
 local copied=s.valid and s.total==s.copy
 local after_exit=a.exited and a.last_change and a.last_change>=a.start
 local valid_context=a.first_zero~=nil
 local verdict="unverified"
 if not a.exited then verdict="gameplay_interrupted"
 elseif not valid_context then verdict="five_flags_unobserved"
 elseif not s.valid then verdict="unreadable"
 elseif not s.coherent then verdict="arithmetic_mismatch"
 elseif not stable then verdict="not_stable"
 elseif not copied then verdict="copy_not_synchronized"
 elseif not fresh then verdict="possible_residual"
 elseif s.bonus>0 then verdict="positive_bonus_candidate"
 elseif s.time>0 then verdict="time_only_candidate"
 else verdict="zero_score_candidate" end
 local category=s.valid and (s.bonus>0 and "BONUS_POSITIVE" or (s.time>0 and "TIME_ONLY" or "ZERO")) or "UNREADABLE"
 csv("score_auto_trials_v33.csv",
 "session,id,start_frame,first_fifth_flag_frame,exit_frame,end_frame,category,time_score,bonus_score,total_score,copy_total,arithmetic_ok,copy_ok,stable_frames,changed_since_start,first_change,last_change,change_count,verdict,finish_reason",
 {session,a.id,a.start,a.first_zero or "",a.exited or "",s.frame,category,
 s.time or "",s.bonus or "",s.total or "",s.copy or "",s.coherent and 1 or 0,
 copied and 1 or 0,s.frame-a.stable_since,fresh and 1 or 0,a.first_change or "",
 a.last_change or "",a.changes,verdict,reason})
 event(a.id,s,"final_candidate",verdict)
 print("[score_probe] "..a.id.." "..verdict.." time="..tostring(s.time).." bonus="..tostring(s.bonus))
 active=nil
 post_exit_suppress=true
end
local function observe(s)
 local in_game=s.gameplay
 if in_game then
  consecutive=consecutive+1
 else consecutive=0 end
 if active==nil and not post_exit_suppress and consecutive==ENTER_FRAMES and s.remaining==5 then
  start(s)
 end
 if active then
  local a=active
  local k=key(s)
  if k~=a.latest_key then
   local prior=a.latest_key
   a.latest_key=k;a.stable_since=s.frame;a.changes=a.changes+1
   a.first_change=a.first_change or s.frame
   a.last_change=s.frame
   if a.exited then a.post_exit_changes=a.post_exit_changes+1 end
   csv("score_auto_transitions_v33.csv",
   "session,id,frame,phase,old_tuple,new_tuple,gs,ptr,remaining",
   {session,a.id,s.frame,a.exited and "POST_EXIT" or "GAMEPLAY",prior,k,s.gs or "",s.ptr or "",s.remaining or ""})
  end
  if in_game and s.remaining==0 and a.first_zero==nil then
   a.first_zero=s.frame;event(a.id,s,"fifth_flag_candidate","remaining_0")
  end
  if not in_game and not a.exited then
   a.exited=s.frame;event(a.id,s,"gameplay_exit_candidate","no_confirmed_record_screen")
  end
  if not a.exited and s.frame-a.start>MAX_GAME_FRAMES then endtrial(s,"gameplay_timeout")
  elseif a.exited then
   local age=s.frame-a.exited
   if s.frame-a.stable_since>=STABLE_FRAMES and age>=STABLE_FRAMES and
      s.valid and s.coherent and s.total==s.copy then
    endtrial(s,"stable_post_exit")
   elseif age>=POST_EXIT_FRAMES then endtrial(s,"post_exit_timeout")
   elseif in_game and consecutive>=ENTER_FRAMES then endtrial(s,"new_game_before_resolution") end
  end
 end
 if post_exit_suppress and not in_game then post_exit_suppress=false end
 old_gameplay=in_game
end
print("[score_probe] v3.3 AUTOMATIC read-only; WRAM score + provisional gameplay context; session="..session)
print("[score_probe] no commands required; reports in "..dir)
while true do
 observe(sample())
 emu.frameadvance()
end
