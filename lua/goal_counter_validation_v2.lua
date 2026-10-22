-- DRIBBLE Goal Counter Validation v2. Passive, never presses buttons.
local root="."
local marker="lua/challenge/dribble_goal_v0325.lua"
local f=io.open(root.."/"..marker,"rb")
if f then f:close() else root="C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode" end
local events=root.."/goal_counter_events_v2.txt"
local trace=root.."/goal_counter_validation_v2.csv"
local sessions=root.."/goal_counter_sessions_v2.csv"
local function setup(p,h)
 local f=assert(io.open(p,"a+"));if f:seek("end")==0 then f:write(h.."\n") end;f:close()
end
setup(trace,"session,frame,event,operator_event,goal_u16,goal_low_u8,goal_high_u8,gs_u16,remaining_u8,player_x,player_y,ball_x,ball_y,time_raw_u8,bonus_raw_u8,delta_goal,read_consistent")
setup(sessions,"session,start_frame,initial_goal,first_positive_frame,first_positive_delta,gs_at_increment,remaining_at_increment,confirmed_visual,negative_visual,exit_observed,final_frame,final_goal,classification")
local function rd(fn,a) local ok,v=pcall(fn,a,"WRAM");if ok then return v end end
local function snapshot()
 return {frame=emu.framecount(),goal=rd(memory.read_u16_le,0x0DA2),
 lo=rd(memory.read_u8,0x0DA2),hi=rd(memory.read_u8,0x0DA3),
 gs=rd(memory.read_u16_le,0x00BA),flags=rd(memory.read_u8,0x06B4),
 px=rd(memory.read_s16_le,0x0F2A),py=rd(memory.read_s16_le,0x0F2C),
 bx=rd(memory.read_s16_le,0x042A),by=rd(memory.read_s16_le,0x042C),
 time=rd(memory.read_u8,0x14F0),bonus=rd(memory.read_u8,0x14F4)}
end
local function write(p,cols,n)
 local a={};for i=1,n do a[i]=cols[i]==nil and "" or tostring(cols[i]) end
 local f=assert(io.open(p,"a"));f:write(table.concat(a,",").."\n");f:close()
end
local id_prefix=os.date("!%Y%m%dT%H%M%SZ")
local ordinal=0;local q=nil;local prev=nil
local function start(s)
 ordinal=ordinal+1
 q={id=id_prefix.."_"..tostring(s.frame).."_"..ordinal,
 started=s.frame,initial=s.goal,visual=false,negative=false,exit=false,
 first_frame=nil,first_delta=nil,gs=nil,remaining=nil}
end
local function log(s,event,operator,delta)
 write(trace,{q and q.id,s.frame,event,operator,s.goal,s.lo,s.hi,s.gs,s.flags,s.px,s.py,s.bx,s.by,s.time,s.bonus,delta,
 (s.goal and s.lo and s.hi and s.goal==(s.lo+256*s.hi)) and 1 or 0},17)
end
local function finish(s,why)
 if not q then return end
 local cls="unverified"
 if q.first_frame then
  cls=q.visual and not q.negative and "positive_correlated_visual" or
   (q.negative and "conflicting_negative_evidence" or "increment_unverified")
 elseif q.visual then cls="visual_goal_without_increment"
 elseif q.negative then cls="negative_control_no_increment" end
 write(sessions,{q.id,q.started,q.initial,q.first_frame,q.first_delta,q.gs,q.remaining,
 q.visual and 1 or 0,q.negative and 1 or 0,q.exit and 1 or 0,s.frame,s.goal,cls},13)
 log(s,"session_closed_"..why,"",nil)
 q=nil
end
local pos=0;local ef=io.open(events,"rb")
if ef then pos=ef:seek("end");ef:close() end
local function poll(s)
 local f=io.open(events,"rb");if not f then return end
 local size=f:seek("end");if size<pos then pos=0 end;f:seek("set",pos)
 while true do
  local at=f:seek();local cmd=f:read("*l");if not cmd then break end
  local after=f:seek()
  if after==size and size>0 then
   local tail=io.open(events,"rb")
   if tail then tail:seek("set",size-1);local endch=tail:read(1);tail:close()
    if endch~="\n" then f:seek("set",at);break end
   end
  end
  pos=after;cmd=cmd:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
  if cmd=="START" then
   if q then finish(s,"restart") end
   start(s);log(s,"operator_start",cmd)
  elseif cmd=="GOAL_VISUAL_CONFIRMED" and q then q.visual=true;log(s,"operator_visual",cmd)
  elseif (cmd=="SHOT_MISSED" or cmd=="NO_GOAL_EXIT") and q then
   q.negative=true;log(s,"operator_negative",cmd)
  elseif cmd=="BEFORE_SHOT" or cmd=="RESULT_SCREEN" then
   if q then log(s,"operator_marker",cmd) end
  elseif cmd=="STOP" and q then finish(s,"stop")
  end
 end
 f:close()
end
print("[GOAL VALIDATION v2] passive; events="..events)
while true do
 local s=snapshot()
 if not q then
  -- Session START is explicit to avoid grouping the wrong gameplay/mode.
  poll(s)
 else
  local change=prev and s.goal~=prev.goal
  local transition=prev and (s.gs~=prev.gs or s.flags~=prev.flags)
  if change then
   local delta=(type(s.goal)=="number" and type(prev.goal)=="number") and s.goal-prev.goal or nil
   if delta and delta>0 and not q.first_frame then
    q.first_frame=s.frame;q.first_delta=delta;q.gs=s.gs;q.remaining=s.flags
   end
   log(s,"goal_counter_change","",delta)
  elseif transition then log(s,"game_state_change","") end
  if prev and s.gs~=prev.gs and s.gs~=0 then q.exit=true end
  poll(s)
 end
 prev=s
 emu.frameadvance()
end
