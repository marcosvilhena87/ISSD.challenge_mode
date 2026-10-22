-- DRIBBLE v0.3.2.2: diagnostics and adaptive bounded stuck escape.
-- Original flag waypoint and goal policies remain unchanged.
local Base=require("challenge.dribble_goal_v031")
local M={MAX_RECOVERIES=2,PROBE_FRAMES=12,MIN_DISPLACEMENT=3}
local function sync(st)
 st.phase=st.base.phase;st.flags_frame=st.base.flags_frame
 st.shot_frame=st.base.shot_frame;st.exit_frame=st.base.exit_frame
end
local function reset(st,s)
 local f=st.base.base.flag
 f.motion_frame=s.frame;f.motion_x=s.px;f.motion_y=s.py
 f.moving_frames=0;f.grace_until=s.frame+20
end
local function own(s) return s.poss==0x0F00 end
local function pick(s,number)
 -- Prefer recovering ball if it is separated from player; otherwise take the
 -- shortest transverse escape relative to the actual next waypoint.
 local bx,by=s.bx-s.px,s.by-s.py
 if not own(s) and (math.abs(bx)>34 or math.abs(by)>34) then
  if math.abs(bx)>=math.abs(by) then return bx>=0 and "Right" or "Left","ball"
  else return by>=0 and "Down" or "Up","ball" end
 end
 local tx,ty=555,261 -- first waypoint fallback; target chosen below by remaining count
 local W={{555,261},{772,304},{974,356},{1228,293},{1450,367}}
 local point=W[math.max(1,math.min(5,6-s.remaining))] or W[1]
 tx,ty=point[1],point[2]
 local dy=ty-s.py
 if number%2==1 then return dy>=0 and "Down" or "Up","transverse" end
 local dx=tx-s.px
 return dx>=0 and "Right" or "Left","longitudinal"
end
function M.new()
 return {base=Base.new(),phase="flags",event="",flags_frame=nil,shot_frame=nil,exit_frame=nil,
   recovery=nil,recoveries=0,diag="",last_recovery=nil}
end
local function diagnostics(st,s,kind)
 local r=st.recovery
 st.diag=table.concat({kind,tostring(st.recoveries),tostring(s.px),tostring(s.py),
    tostring(s.bx),tostring(s.by),tostring(s.poss),tostring(s.remaining),
    r and r.direction or "",r and r.strategy or ""},"|")
end
function M.step(s,st)
 st=st or M.new();st.event="";st.diag=""
 if st.recovery then
  local r=st.recovery
  if type(s.frame)~="number" or type(s.px)~="number" or type(s.py)~="number" or
     type(s.gs)~="number" or type(s.ptr)~="number" or type(s.remaining)~="number" or
     type(s.poss)~="number" or type(s.bx)~="number" or type(s.by)~="number" then
   st.event="recovery_invalid_read";return {},st,"invalid_read"
  end
  if s.gs~=0 or s.ptr~=0x0F00 or s.remaining~=r.remaining then
   st.recovery=nil
   local b,v,why=Base.step(s,st.base);st.base=v;st.event=v.event;sync(st)
   return b,st,why
  end
  local displacement=math.abs(s.px-r.x)+math.abs(s.py-r.y)
  if displacement>=M.MIN_DISPLACEMENT then
   diagnostics(st,s,"recovered");st.last_recovery=st.diag
   st.recovery=nil;reset(st,s);st.recoveries=0
   st.event="stuck_recovered";return {},st,"recovery_completed"
  end
  if s.frame-r.frame>=M.PROBE_FRAMES then
   diagnostics(st,s,"probe_failed");st.last_recovery=st.diag
   st.recovery=nil;reset(st,s)
   if st.recoveries>=M.MAX_RECOVERIES then
    st.event="stuck_recovery_exhausted";return {},st,"stuck_recovery_exhausted"
   end
   st.event="stuck_recovery_retry";return {},st,"recovery_retry"
  end
  diagnostics(st,s,"probing")
  return {[r.direction]=true},st,"stuck_recovery"
 end
 local b,v,why=Base.step(s,st.base)
 st.base=v;st.event=v.event;sync(st)
 if st.event:find("flag_collected",1,true) then st.recoveries=0 end
 if why~="stuck" or st.phase~="flags" then return b,st,why end
 if st.recoveries>=M.MAX_RECOVERIES then st.event="stuck_recovery_exhausted";return {},st,"stuck_recovery_exhausted" end
 st.recoveries=st.recoveries+1
 local direction,strategy=pick(s,st.recoveries)
 st.recovery={frame=s.frame,x=s.px,y=s.py,remaining=s.remaining,
    direction=direction,strategy=strategy}
 diagnostics(st,s,"started")
 st.event="stuck_recovery_started"
 return {},st,"stuck_recovery"
end
return M
