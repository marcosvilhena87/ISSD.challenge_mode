-- v0.3.2.1: bounded recovery around the unchanged v0.3.1 control policy.
local Base=require("challenge.dribble_goal_v031")
local M={}
M.RECOVERY_FRAMES=24
M.MAX_RECOVERIES=2
M.MIN_DISPLACEMENT=3
function M.new()
 return {base=Base.new(),phase="flags",event="",flags_frame=nil,shot_frame=nil,exit_frame=nil,
         recovery=nil,recoveries=0,recovery_target=nil}
end
local function sync(st)
 st.phase=st.base.phase;st.flags_frame=st.base.flags_frame
 st.shot_frame=st.base.shot_frame;st.exit_frame=st.base.exit_frame
end
local function reset_watchdog(flag,s)
 flag.motion_frame=s.frame;flag.motion_x=s.px;flag.motion_y=s.py
 flag.moving_frames=0;flag.grace_until=s.frame+30
end
function M.step(s,st)
 st=st or M.new();st.event=""
 if st.recovery then
  local valid=type(s.frame)=="number" and type(s.gs)=="number" and
              type(s.ptr)=="number" and type(s.remaining)=="number" and
              type(s.px)=="number" and type(s.py)=="number"
  if not valid then return {},st,"invalid_read" end
  if s.gs~=0 or s.ptr~=0x0F00 then
   st.recovery=nil
   local b,base,why=Base.step(s,st.base);st.base=base;st.event=base.event;sync(st)
   return b,st,why
  end
  if s.remaining~=st.recovery.remaining then
   st.recovery=nil;st.recoveries=0
   reset_watchdog(st.base.base.flag,s)
   local b,base,why=Base.step(s,st.base);st.base=base;st.event=base.event;sync(st)
   return b,st,why
  end
  local r=st.recovery
  local d=math.abs(s.px-r.x)+math.abs(s.py-r.y)
  if d>=M.MIN_DISPLACEMENT then
   st.recovery=nil;reset_watchdog(st.base.base.flag,s)
   st.event="stuck_recovered"
   return {},st,"recovery_completed"
  end
  if s.frame-r.frame>=M.RECOVERY_FRAMES then
   st.recovery=nil;reset_watchdog(st.base.base.flag,s)
   if st.recoveries>=M.MAX_RECOVERIES then
    st.event="stuck_recovery_exhausted"
    return {},st,"stuck_recovery_exhausted"
   end
   st.event="stuck_recovery_retry"
   return {},st,"recovery_retry"
  end
  -- Short directional escape probes, alternating transverse direction.
  local phase=math.floor((s.frame-r.frame)/6)%2
  if r.number%2==1 then
   return phase==0 and {Down=true} or {Right=true},st,"stuck_recovery"
  end
  return phase==0 and {Up=true} or {Left=true},st,"stuck_recovery"
 end
 local buttons,base,why=Base.step(s,st.base)
 st.base=base;st.event=base.event;sync(st)
 if st.event:find("flag_collected",1,true) then st.recoveries=0 end
 if why~="stuck" or st.phase~="flags" then return buttons,st,why end
 if st.recoveries>=M.MAX_RECOVERIES then
  st.event="stuck_recovery_exhausted";return {},st,"stuck_recovery_exhausted"
 end
 st.recoveries=st.recoveries+1
 st.recovery={frame=s.frame,x=s.px,y=s.py,remaining=s.remaining,number=st.recoveries}
 st.event="stuck_recovery_started"
 return {},st,"stuck_recovery"
end
return M
