-- v0.3.2.3 Delayed Movement Detection: preserve the original pilot.
local Base=require("challenge.dribble_goal_v0322")
local M={OBSERVE_FRAMES=18,MIN_PLAYER_MOVE=3,MIN_BALL_MOVE=3}
function M.new()
 return {base=Base.new(),phase="flags",event="",diag="",flags_frame=nil,shot_frame=nil,
 exit_frame=nil,observation=nil,recoveries=0,detected_delays=0}
end
local function sync(st)
 st.phase=st.base.phase;st.flags_frame=st.base.flags_frame
 st.shot_frame=st.base.shot_frame;st.exit_frame=st.base.exit_frame
 st.recoveries=st.base.recoveries
end
local function dist(a,b,c,d) return math.abs(a-c)+math.abs(b-d) end
local function reset(st,s)
 local flag=st.base.base.base.flag
 flag.motion_frame=s.frame;flag.motion_x=s.px;flag.motion_y=s.py
 flag.moving_frames=0;flag.grace_until=s.frame+20
end
local function diagnostic(st,s,kind,pd,bd)
 local o=st.observation
 st.diag=table.concat({kind,tostring(o and o.start or ""),tostring(s.frame),
 tostring(pd),tostring(bd),tostring(s.poss),tostring(s.remaining),
 tostring(o and o.kind or ""),tostring(st.recoveries)},"|")
end
function M.step(s,st)
 st=st or M.new();st.event="";st.diag=""
 if st.observation then
  local o=st.observation
  if type(s.frame)~="number" or type(s.gs)~="number" or type(s.ptr)~="number"
   or type(s.remaining)~="number" or type(s.px)~="number" or type(s.py)~="number"
   or type(s.bx)~="number" or type(s.by)~="number" or type(s.poss)~="number" then
   st.observation=nil;st.event="delayed_invalid_read";return {},st,"invalid_read"
  end
  if s.gs~=0 or s.ptr~=0x0F00 or s.remaining~=o.remaining then
   st.observation=nil
   local b,v,why=Base.step(s,st.base);st.base=v;st.event=v.event;sync(st)
   return b,st,why
  end
  local pd=dist(s.px,s.py,o.px,o.py)
  local bd=dist(s.bx,s.by,o.bx,o.by)
  diagnostic(st,s,"observing",pd,bd)
  if pd>=M.MIN_PLAYER_MOVE then
   diagnostic(st,s,"player_delayed",pd,bd)
   st.detected_delays=st.detected_delays+1
   st.observation=nil;reset(st,s)
   st.event="delayed_player_movement"
   return {},st,"movement_detected"
  end
  if bd>=M.MIN_BALL_MOVE then
   -- Ball motion is evidence of response, not proof that the player is moving.
   -- Preserve this evidence, but do not prematurely classify the stall as resolved.
   o.ball_moved=true
  end
  if s.frame-o.start>=M.OBSERVE_FRAMES then
   diagnostic(st,s,o.ball_moved and "ball_only" or "no_motion",pd,bd)
   st.observation=nil
   if o.ball_moved then
    -- Re-evaluate on a fresh watchdog window instead of stacking probes.
    reset(st,s)
    st.event="delayed_ball_only"
    return {},st,"movement_observed_ball_only"
   end
   st.event="delayed_no_movement"
   return {},st,"observation_timeout"
  end
  -- Passive wait, no directional input; isolate delayed effects from new commands.
  return {},st,"delayed_observation"
 end
 local buttons,base,why=Base.step(s,st.base)
 st.base=base;st.event=base.event;sync(st)
 if why=="recovery_retry" or why=="stuck_recovery_exhausted" then
  -- A probe just ended: observe latency before another probe or terminal failure.
  -- Retry/exhaustion is deferred until this window expires.
  st.observation={start=s.frame,px=s.px,py=s.py,bx=s.bx,by=s.by,
                  remaining=s.remaining,kind=why,ball_moved=false}
  st.event="delayed_observation_started"
  diagnostic(st,s,"started",0,0)
  return {},st,"delayed_observation"
 end
 return buttons,st,why
end
return M
