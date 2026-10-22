-- DRIBBLE Dash approach calibration v3. Pure policy; no BizHawk dependencies.
-- Stop Y before precision with adaptive braking from measured closing speed.
local M={MIN_START=100,MIN_BRAKE=60,MAX_BRAKE=145,LOOKAHEAD=12,MAX_GAP=24}
function M.new()
 return {previous=nil,active=false,flag=nil,frames={},starts={},stops={},last_reason="",minimum={},last_off={},last_off_cause={}}
end
local function number(x) return type(x)=="number" end
function M.step(st,buttons,s,reason,waypoints)
 assert(type(st)=="table" and type(buttons)=="table")
 buttons.Y=nil
 local remaining=s.remaining
 local flag=number(remaining) and remaining>=1 and remaining<=5 and 6-remaining or nil
 local wp=flag and waypoints[flag] or nil
 local valid=wp and number(s.frame) and number(s.px) and number(s.py) and number(s.bx)
  and number(s.by) and s.gs==0 and s.ptr==0x0F00 and s.poss==0x0F00
 local geometry=wp and number(s.frame) and number(s.px) and number(s.py)
 local distance,closing,brake
 if geometry then
  local dx,dy=wp[1]-s.px,wp[2]-s.py
  distance=math.sqrt(dx*dx+dy*dy)
  st.minimum[flag]=math.min(st.minimum[flag] or distance,distance)
  local p=st.previous
  closing=0
  if p and p.flag==flag and s.frame>p.frame and s.frame-p.frame<=3 then
   local vx=(s.px-p.px)/(s.frame-p.frame)
   local vy=(s.py-p.py)/(s.frame-p.frame)
   if distance>0 then closing=math.max(0,(dx*vx+dy*vy)/distance) end
  end
  brake=math.max(M.MIN_BRAKE,math.min(M.MAX_BRAKE,M.MIN_BRAKE+closing*M.LOOKAHEAD))
 end
 local moving=buttons.Left or buttons.Right or buttons.Up or buttons.Down
 local gap=geometry and number(s.bx) and number(s.by) and math.sqrt((s.bx-s.px)^2+(s.by-s.py)^2) or nil
 local safe=valid and reason=="waypoint" and moving and not buttons.B and gap<=M.MAX_GAP
 local threshold=st.active and brake or math.max(M.MIN_START,brake or M.MIN_START)
 local enabled=not not (safe and distance>=threshold)
 local cause
 if not enabled then
  if not geometry or not number(s.bx) or not number(s.by) then cause="invalid_read"
  elseif s.gs~=0 or s.ptr~=0x0F00 then cause="context_exit"
  elseif s.poss~=0x0F00 then cause="possession"
  elseif reason=="precision_approach" then cause="precision_approach"
  elseif reason~="waypoint" then cause=reason or "other_phase"
  elseif not moving then cause="no_direction"
  elseif buttons.B then cause="shot_input"
  elseif gap>M.MAX_GAP then cause="ball_gap"
  elseif distance<threshold then cause="braking_distance"
  else cause="other" end
 end
 local events={}
 if st.active and (not enabled or st.flag~=flag) then
  st.stops[st.flag]=(st.stops[st.flag] or 0)+1
  st.last_off[st.flag]=s.frame;st.last_off_cause[st.flag]=cause or "flag_change"
  events[#events+1]={kind="dash_off",flag=st.flag,frame=s.frame,distance=distance,brake=brake,closing=closing,reason=reason,cause=cause or "flag_change",gap=gap}
 end
 if enabled and (not st.active or st.flag~=flag) then
  st.starts[flag]=(st.starts[flag] or 0)+1
  events[#events+1]={kind="dash_on",flag=flag,frame=s.frame,distance=distance,brake=brake,closing=closing,reason=reason}
 end
 st.active=enabled;st.flag=flag;st.last_reason=reason
 if enabled then buttons.Y=true;st.frames[flag]=(st.frames[flag] or 0)+1 end
 if valid then st.previous={frame=s.frame,px=s.px,py=s.py,flag=flag} else st.previous=nil end
 return buttons,enabled,events,{distance=distance,brake=brake,closing=closing,gap=gap,cause=cause}
end
function M.flag_summary(st,flag,frame)
 return {minimum=st.minimum[flag],off_frame=st.last_off[flag],off_cause=st.last_off_cause[flag],
  frames_since_off=st.last_off[flag] and frame-st.last_off[flag] or nil}
end
return M
