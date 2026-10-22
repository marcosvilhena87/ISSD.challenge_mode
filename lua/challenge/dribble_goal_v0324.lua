-- v0.3.2.4: initial movement calibration, without changing waypoint or shot policies.
local Base=require("challenge.dribble_goal_v0323")
local M={CALIBRATION_FRAMES=90,MIN_MOVE=3}
local function distance(x,y,a,b) return math.abs(x-a)+math.abs(y-b) end
function M.new()
 return {base=Base.new(),phase="flags",event="",diag="",flags_frame=nil,shot_frame=nil,
 exit_frame=nil,calibration=nil,calibration_done=false,calibration_result=nil}
end
local function sync(st)
 st.phase=st.base.phase
 st.flags_frame=st.base.flags_frame;st.shot_frame=st.base.shot_frame;st.exit_frame=st.base.exit_frame
end
local function valid(s)
 for _,k in ipairs({"frame","gs","ptr","remaining","px","py","bx","by","poss"}) do
  if type(s[k])~="number" then return false end
 end
 return true
end
function M.step(s,st)
 st=st or M.new();st.event="";st.diag=""
 if not valid(s) then return {},st,"invalid_read" end
 if not st.calibration and not st.calibration_done and s.gs==0 and s.ptr==0x0F00 and s.remaining==5 then
  st.calibration={start=s.frame,px=s.px,py=s.py,bx=s.bx,by=s.by,
   first_player=nil,first_ball=nil,first_possession_change=nil,initial_poss=s.poss,
   last_frame=s.frame}
  st.event="initial_calibration_started"
 end
 local c=st.calibration
 if c then
  local age=s.frame-c.start
  if age<0 then return {},st,"frame_discontinuity" end
  local pd=distance(s.px,s.py,c.px,c.py)
  local bd=distance(s.bx,s.by,c.bx,c.by)
  if not c.first_player and pd>=M.MIN_MOVE then c.first_player=s.frame end
  if not c.first_ball and bd>=M.MIN_MOVE then c.first_ball=s.frame end
  if not c.first_possession_change and s.poss~=c.initial_poss then c.first_possession_change=s.frame end
  c.last_frame=s.frame
  st.diag=table.concat({"initial",age,pd,bd,s.poss,s.remaining,
    c.first_player or "",c.first_ball or "",c.first_possession_change or ""},"|")
  if age>=M.CALIBRATION_FRAMES or s.remaining~=5 or s.gs~=0 or s.ptr~=0x0F00 then
   st.calibration_result={start=c.start,finish=s.frame,first_player=c.first_player,
    first_ball=c.first_ball,first_possession_change=c.first_possession_change,
    classification=c.first_player and "player_moved" or
      (c.first_ball and "ball_only" or "no_motion"),
    outcome=(s.remaining~=5 and "flag_transition" or
      ((s.gs~=0 or s.ptr~=0x0F00) and "gameplay_exit" or "window_complete"))}
   st.calibration=nil;st.calibration_done=true
   st.event="initial_calibration_completed"
  end
 end
  -- Apply startup grace before the base watchdog evaluates this frame.
  if c and st.base.base and st.base.base.base and st.base.base.base.base and st.base.base.base.base.flag then
   local flag=st.base.base.base.base.flag
   flag.grace_until=math.max(flag.grace_until or 0,c.start+M.CALIBRATION_FRAMES)
  end
 local buttons,base,why=Base.step(s,st.base);st.base=base;sync(st)
 -- Initial movement can be delayed: postpone first watchdog expiry without changing
 -- the chosen input. Calibration is passive observation, never a new movement command.
 if c and st.phase=="flags" and st.base.base and st.base.base.base and
   st.base.base.base.base and st.base.base.base.base.flag then
  local flag=st.base.base.base.base.flag
  flag.grace_until=math.max(flag.grace_until or 0,c.start+M.CALIBRATION_FRAMES)
 end
 if base.event~="" then st.event=st.event=="" and base.event or (st.event.."|"..base.event) end
 return buttons,st,why
end
return M
