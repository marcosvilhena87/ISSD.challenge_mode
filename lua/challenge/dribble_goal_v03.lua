-- DRIBBLE v0.3: waypoint collection + experimental goal approach.
local Flags=require("challenge.dribble_waypoints_v022")
local M={}
M.GOAL_X=1650 -- EXPERIMENTAL target; not measured goal coordinates.
M.GOAL_Y=365
M.GOAL_TIMEOUT=900
function M.new() return {phase="flags",flag=Flags.new(),goal_started=nil,shot_started=nil,shot_attempts=0,events={}} end
function M.step(s,st)
 st=st or M.new();st.events={}
 if type(s.frame)~="number" or type(s.gs)~="number" or type(s.ptr)~="number" or type(s.remaining)~="number" then return {},st,"invalid_read" end
 if s.gs~=0 or s.ptr~=0x0F00 then
  if st.phase=="goal" then st.events={"gameplay_exit_unverified"} end
  return {},st,"gameplay_exit_unverified"
 end
 if st.phase=="flags" then
  local buttons,flag,reason=Flags.step(s,st.flag);st.flag=flag
  if flag.event=="flag_collected" then st.events={"flag_collected"} end
  if reason=="five_collected" then
   st.phase="goal";st.goal_started=s.frame;st.events={"five_flags_collected","goal_phase_started"}
  else return buttons,st,reason end
 end
 if st.phase~="goal" then return {},st,"invalid_phase" end
 if s.frame-st.goal_started>=M.GOAL_TIMEOUT then return {},st,"goal_timeout" end
 if s.remaining~=0 then return {},st,"counter_discontinuity" end
 if type(s.px)~="number" or type(s.py)~="number" or type(s.bx)~="number" or type(s.by)~="number" or type(s.poss)~="number" then return {},st,"invalid_read" end
 local buttons={}
 local dx,dy=M.GOAL_X-s.px,M.GOAL_Y-s.py
 local owns=s.poss==0x0F00
 if not owns and (math.abs(s.bx-s.px)>35 or math.abs(s.by-s.py)>35) then
  dx,dy=s.bx-s.px,s.by-s.py
 end
 if dx>10 then buttons.Right=true elseif dx< -10 then buttons.Left=true end
 if dy>14 then buttons.Down=true elseif dy< -14 then buttons.Up=true end
 local reason="goal_approach"
 if math.abs(dx)<=55 and math.abs(dy)<=55 and owns then
  -- Controlled experimental B hold/release; no goal detected without independent evidence.
  if not st.shot_started then st.shot_started=s.frame;st.shot_attempts=st.shot_attempts+1;st.events={"shot_started"} end
  local age=s.frame-st.shot_started
  if age<20 then buttons={Right=true,B=true};reason="shot_charge"
  elseif age==20 then buttons={Right=true};reason="shot_release";st.events={"shot_released"}
  else buttons={};reason="await_goal_observation" end
 end
 return buttons,st,reason
end
return M
