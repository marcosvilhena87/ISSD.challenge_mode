-- v0.8.23: progress-guided approach with bounded axis switching.
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.72",ROUTE={6,2,3,4,5,8,9,7,10,11},MAX_APPROACH=90,MAX_APPROACH_ABSOLUTE=210,EXTEND_FRAMES=30,BURST_FRAMES=4,CONTINUOUS_HOLD_710=24,CONTINUOUS_HOLD_67=12,STALL_WINDOW=6}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.next(_,holder,visited)
 visited=visited or {}
 if not holder or holder<2 or holder>11 then return nil,"invalid_holder" end
 -- If the ball is at 9 and 7 has not received, 9→7 is the primary route.
 if holder==9 and not visited[7] then return 7,"primary_9_to_7" end
 -- 6→7 is fallback only after a genuine return of possession to 6.
 if holder==6 and visited[9] and not visited[7] then return 7,"fallback_6_to_7" end
 for _,id in ipairs(M.ROUTE) do
  -- A previous 6→2 pass does not prohibit 6→7: only the receiver must be new.
  if id~=holder and not visited[id] then return id,"ordered_remaining" end
 end
 return nil,"all_visited"
end
function M.can_relay_six_seven(holder,visited)
 -- Six may be visited already; seven is eligible until seven itself receives.
 return holder==6 and not (visited and visited[7])
end
function M.goalward_checkpoint(state,frames,measurement)
 -- A checkpoint only extends a per-stage deadline, NEVER the absolute cap.
 if not state or not measurement or type(measurement.distance)~="number" then return false,"missing_measurement" end
 if (state.pair_710_checkpoints or 0)>=2 then return false,"checkpoint_budget" end
 if frames>=M.MAX_APPROACH_ABSOLUTE then return false,"absolute_limit" end
 if (state.pair_710_last_carrier or 0)<=0.5 or (state.pair_710_right_streak or 0)<2 then
  return false,"carrier_not_advancing"
 end
 local baseline=state.pair_710_checkpoint_distance or state.initial_distance
 if not baseline or baseline-measurement.distance<25 or measurement.distance>state.best_distance+12 then return false,"insufficient_stage_gain" end
 return true,"goalward_receiver_stage_progress"
end
function M.can_extend(state,frames,measurement)
 if frames>=M.MAX_APPROACH_ABSOLUTE or not measurement then return false,"absolute_limit_or_missing_measurement" end
 if not state or type(state.initial_distance)~="number" or type(state.best_distance)~="number" then return false,"insufficient_progress_evidence" end
 if state and (state.pair_89_carrier_progress_streak or 0)>=2
   and (state.pair_89_extension_count or 0)<2
   and (state.pair_89_carrier_stall or 0)==0
   and (state.pair_89_last_carrier or 0)>0.5 then
  return true,"pair_89_receiver_escape_progress"
 end
 if state and (state.pair_710_right_streak or 0)>=2
   and (state.pair_710_extension_count or 0)<2
   and (state.pair_710_last_carrier or 0)>0.5
   and (state.pair_710_recent_net_gain or 0)>=8
   and measurement.distance<=state.best_distance+12 then
  return true,"pair_710_recent_right_progress"
 end
 if state and state.pair_67_up_streak and state.pair_67_up_streak>=2
    and (state.pair_67_extension_count or 0)<2
    and (state.pair_67_last_gain or 0)>0.5
    and measurement.distance<=(state.pair_67_last_distance or measurement.distance)+1 then
  return true,"pair_67_recent_up_progress"
 end
 if state and state.recent_progress and state.recent_progress>=2 and
   measurement.distance<=state.best_distance+12 and
   (state.stalled or 0)<M.STALL_WINDOW and
   (state.recent_extension_count or 0)<2 then
  return true,"recent_progress_verified"
 end
 if (state.stalled or 0)>=M.STALL_WINDOW then return false,"stalled" end
 if state.initial_distance-state.best_distance<12 then return false,"insufficient_net_progress" end
 if measurement.distance>state.best_distance+12 then return false,"regressed" end
 return true,"progress_verified"
end
-- Feedback controller: evaluate the actual geometric result of each burst.
-- Negative feedback is associated with a direction, never blindly with an axis.
local KEYS={{"Right",1,0},{"Left",-1,0},{"Down",0,1},{"Up",0,-1}}
local function cost(distance,lateral)
 return math.max(0,distance-Feet.MAX_RANGE)+2*math.max(0,lateral-Feet.MAX_LATERAL)
end
function M.score(metrics)
 if not metrics then return math.huge end
 return cost(metrics.distance,metrics.lateral)
end
-- Short-horizon receiver forecast. Only neutral observations update velocity;
-- stale or erratic estimates are discarded rather than extrapolated.
function M.observe_receiver(state,sample,frame,holder,target)
 if not state or holder~=8 or target~=9 then return nil end
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b or type(frame)~="number" then return nil end
 local prev=state.receiver_last
 state.receiver_last={x=b.x,y=b.y,frame=frame}
 if not prev then return nil end
 local dt=frame-prev.frame
 if dt<1 or dt>12 then state.receiver_velocity=nil;return nil end
 local vx,vy=(b.x-prev.x)/dt,(b.y-prev.y)/dt
 if math.abs(vx)>12 or math.abs(vy)>12 then
  state.receiver_velocity=nil;return {valid=false,reason="velocity_outlier",vx=vx,vy=vy}
 end
 local old=state.receiver_velocity
 if old then vx=(old.vx+vx)/2;vy=(old.vy+vy)/2 end
 state.receiver_velocity={vx=vx,vy=vy,frame=frame}
 return {valid=true,vx=vx,vy=vy,holder_x=a.x,holder_y=a.y,receiver_x=b.x,receiver_y=b.y}
end
function M.receiver_prediction(state,sample,holder,target,frame)
 if not state or holder~=8 or target~=9 then return nil end
 local a,b=find(sample,holder),find(sample,target)
 local v=state.receiver_velocity
 if not a or not b or not v or not frame or frame-v.frame>12 then return nil end
 local horizon=4
 local offx=math.max(-24,math.min(24,v.vx*horizon))
 local offy=math.max(-24,math.min(24,v.vy*horizon))
 return {dx=b.x+offx-a.x,dy=b.y+offy-a.y,
  predicted_x=b.x+offx,predicted_y=b.y+offy,
  vx=v.vx,vy=v.vy,horizon=horizon}
end
-- 7->10 short-horizon receiver velocity from stable WRAM samples.
-- Reject outliers and clamp the lead so the bot cannot chase a remote guess.
function M.observe_710(state,sample,frame)
 if not state or type(frame)~="number" then return nil end
 local a,b=find(sample,7),find(sample,10)
 if not a or not b then state.pair_710_velocity=nil;return nil end
 local prior=state.pair_710_receiver_position
 state.pair_710_receiver_position={x=b.x,y=b.y,frame=frame}
 if not prior then return nil end
 local dt=frame-prior.frame
 if dt<1 or dt>12 then state.pair_710_velocity=nil;return nil end
 local vx,vy=(b.x-prior.x)/dt,(b.y-prior.y)/dt
 if math.abs(vx)>12 or math.abs(vy)>12 then state.pair_710_velocity=nil;return nil end
 local old=state.pair_710_velocity
 if old then vx=(vx+old.vx)/2;vy=(vy+old.vy)/2 end
 state.pair_710_velocity={vx=vx,vy=vy,frame=frame}
 return state.pair_710_velocity
end
function M.predict_710(state,sample,frame)
 local a,b=find(sample,7),find(sample,10)
 local v=state and state.pair_710_velocity
 if not a or not b or not v or not frame or frame-v.frame>8 then return nil end
 local horizon=4
 local leadx=math.max(-24,math.min(24,v.vx*horizon))
 local leady=math.max(-24,math.min(24,v.vy*horizon))
 return {dx=b.x+leadx-a.x,dy=b.y+leady-a.y,vx=v.vx,vy=v.vy}
end
function M.step(sample,holder,target,state)
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b or not sample.ball then return {},"missing_geometry" end
 local bx,by=sample.ball.x-a.x,sample.ball.y-a.y
 if bx*bx+by*by>18*18 then return {},"ball_not_at_feet" end
 local safe,why,metrics=Feet.check(sample,holder,target)
 if safe then return {},"target_in_range",metrics end
 if why~="too_far" and why~="diagonal_risk" then return {},why,metrics end
 -- Stop a 7->11 fallback when both absolute and best-relative distances
 -- have worsened after substantial movement; the caller aborts without B.
 if holder==7 and target==11 and state
   and (state.approach_frames or 0)>=24
   and state.initial_distance
   and state.best_distance
   and metrics.distance>state.initial_distance+15
   and metrics.distance>state.best_distance+28 then
  return {},"pair_711_net_regression_stop",metrics
 end
 local dx,dy=metrics.dx,metrics.dy
 if holder==7 and target==10 and state then
  local prediction=M.predict_710(state,sample,state.current_frame)
  if prediction then
   dx,dy=prediction.dx,prediction.dy
   state.pair_710_predicted=prediction
  else
   state.pair_710_predicted=nil
  end
 end
 local forecast=(holder==8 and target==9) and M.receiver_prediction(state,sample,holder,target,state and state.current_frame) or nil
 if forecast then dx,dy=forecast.dx,forecast.dy end
 -- A persistently regressing 6→7 direction is excluded for the next
 -- two decisions; orientation follows real receiver displacement.
 if holder==6 and target==7 and state and state.pair_67_avoid_left and state.pair_67_avoid_left>0 then
  local blocked=state.pair_67_avoid_direction
  state.penalties=state.penalties or {}
  if blocked then state.penalties[blocked]=math.max(state.penalties[blocked] or 0,36) end
 end
 -- 6→7: experimental UP+RIGHT movement (no B). Require the target
 -- to be up-right and use WRAM feedback to retire a regressing diagonal.
 if holder==6 and target==7 and state and dx>8 and dy< -8
   and not state.pair_67_diagonal_disabled
   and (state.pair_67_diagonal_trials or 0)<6 then
  state.direction="Up_Right";state.axis="xy"
  state.geometry_reason="pair_67_up_right_approach"
  return {Up=true,Right=true},"approach_step",metrics
 end
 -- Only after sustained regression, try a bounded cardinal recovery based on
 -- the larger coordinate error. Alternate once after a failed probe.
 if holder==6 and target==7 and state and state.pair_67_diagonal_disabled
    and (state.pair_67_cardinal_attempts or 0)<8 then
  local key
  if (state.pair_67_cardinal_flip or 0)>0 then
    key=(math.abs(dy)>math.abs(dx)) and "Right" or (dy<0 and "Up" or "Down")
  else
    key=(math.abs(dy)>math.abs(dx)) and (dy<0 and "Up" or "Down") or (dx>0 and "Right" or "Left")
  end
  state.pair_67_cardinal_attempts=(state.pair_67_cardinal_attempts or 0)+1
  state.direction=key;state.axis=(key=="Right" or key=="Left") and "x" or "y"
  state.geometry_reason="pair_67_cardinal_recovery"
  return {[key]=true},"approach_step",metrics
 end
 -- Only 6→7: maintain UP while recent neutral feedback proves progress.
 if holder==6 and target==7 and state and state.pair_67_avoid_direction~="Up" and (state.pair_67_up_streak or 0)>=2
   and state.pair_67_last_gain and state.pair_67_last_gain>0.5 then
  state.axis="y";state.direction="Up";state.geometry_reason="pair_67_recent_up_progress"
  return {Up=true},"approach_step",metrics
 end
 -- v0.8.71: 7→11 must follow the measured receiver vector, not
 -- direction locks calibrated on the preceding 7→10 attempt.
 if holder==7 and target==11 and state then
  local opts={}
  if math.abs(dx)>4 then opts[#opts+1]={key=dx>0 and "Right" or "Left",gap=math.abs(dx)} end
  if math.abs(dy)>4 then opts[#opts+1]={key=dy>0 and "Down" or "Up",gap=math.abs(dy)} end
  table.sort(opts,function(a,b) return a.gap>b.gap end)
  local choice=opts[1]
  if choice then
   state.direction=choice.key
   state.axis=(choice.key=="Left" or choice.key=="Right") and "x" or "y"
   state.geometry_reason="pair_711_coordinate_retarget"
   return {[choice.key]=true},"approach_step",metrics
  end
 end
 -- 7->10: select the dominant predicted coordinate error. Re-evaluate
 -- every neutral burst; never persist RIGHT solely because it worked earlier.
 if holder==7 and target==10 and state then
  local key
  if math.abs(dx)>=math.abs(dy) then key=dx>=0 and "Right" or "Left"
  else key=dy>=0 and "Down" or "Up" end
  state.direction=key
  state.axis=(key=="Right" or key=="Left") and "x" or "y"
  state.geometry_reason=state.pair_710_predicted and "pair_710_predictive_chase" or "pair_710_measured_chase"
  return {[key]=true},"approach_step",metrics
 end
 -- 7→10: favor RIGHT only while the carrier actually advances toward
 -- the receiver; receiver escape alone does not revoke this preference.
 if holder==7 and target==10 and state and dx>10
   and (state.pair_710_right_streak or 0)>=2
   and (state.pair_710_last_carrier or 0)>0.5 then
  state.direction="Right";state.axis="x";state.geometry_reason="pair_710_relative_right_progress"
  return {Right=true},"approach_step",metrics
 end
 -- Screen coordinates: positive X goes right; positive Y goes down.
 if holder==5 and target==8 and state and not state.right_suspended and dx>20 and
    (state.recovery_left or 0)==0 then
  state.axis="x";state.direction="Right";state.geometry_reason="coordinate_right"
  return {Right=true},"approach_step",metrics
 end
 if holder==8 and target==9 and dx>10 and dy< -10 and state and not state.diagonal_disabled and
   (state.diagonal_trials or 0)<3 and (state.recovery_left or 0)==0 then
  state.axis="xy";state.direction="Up_Right";state.geometry_reason="coordinate_diagonal"
  return {Up=true,Right=true},"approach_step",metrics
 end

 -- Generic improvement lock: keep a recent good cardinal direction for a
 -- short, bounded period rather than oscillating because of old penalties.
 -- Pair-specific steering above this point retains priority.
 if state and not (holder==6 and target==7 and state.last_good_direction==state.pair_67_avoid_direction and (state.pair_67_avoid_left or 0)>0) and state.last_good_direction and (state.good_direction_streak or 0)>=2
    and (state.good_direction_lock or 0)>0 then
  local key=state.last_good_direction
  state.good_direction_lock=state.good_direction_lock-1
  state.direction=key;state.axis=(key=="Up" or key=="Down") and "y" or "x"
  state.geometry_reason="recent_combined_progress"
  return {[key]=true},"approach_step",metrics
 end
 -- 8→9: limit movement to directions justified by geometry or measured
 -- displacement. A direction contrary to the target is accepted only when
 -- WRAM demonstrates that it reduces the distance.
 if holder==8 and target==9 and state then
  local options={{"Up",0,-1},{"Right",1,0}}
  if dx< -4 then options[#options+1]={"Left",-1,0} end
  if dy>4 then options[#options+1]={"Down",0,1} end
  local best,best_score=nil,math.huge
  for _,entry in ipairs(options) do
   local name,vx,vy=entry[1],entry[2],entry[3]
   local learned=state.motion and state.motion[name]
   local mx,my=vx,vy
   if learned and learned.count>=1 then mx,my=learned.dx,learned.dy end
   local px,py=dx-mx,dy-my
   local predicted=cost(math.sqrt(px*px+py*py),math.min(math.abs(px),math.abs(py)))
   local penalty=state.penalties and state.penalties[name] or 0
   if state.pair_89_last_bad_direction==name then penalty=penalty+18 end
   local value=predicted+penalty
   if value<best_score then best,best_score=name,value end
  end
  if best then
   state.direction=best;state.axis=(best=="Up" or best=="Down") and "y" or "x"
   state.geometry_reason="pair_8_9_measured_cardinal"
   return {[best]=true},"approach_step",metrics
  end
 end
 local choices={}
 for _,entry in ipairs(KEYS) do
  local key,vx,vy=entry[1],entry[2],entry[3]
  -- Evaluate both distance and lateral error for a hypothetical one-unit step.
  local x,y=dx-vx,dy-vy
  local projected=cost(math.sqrt(x*x+y*y),math.min(math.abs(x),math.abs(y)))
  local penalty=state and state.penalties and state.penalties[key] or 0
  local learned=state and state.motion and state.motion[key]
  if learned and learned.count>=2 then
   local nx=dx-learned.dx;local ny=dy-learned.dy
   projected=cost(math.sqrt(nx*nx+ny*ny),math.min(math.abs(nx),math.abs(ny)))
  end
  -- The preferred axis is learned from real observed movement; stale routes
  -- are not allowed to overwrite feedback.
  choices[#choices+1]={key=key,score=projected+penalty,axis=vx~=0 and "x" or "y"}
 end
 table.sort(choices,function(x,y)
  if x.score~=y.score then return x.score<y.score end
  return x.key<y.key
 end)
 local candidate=choices[1]
 if holder==6 and target==7 and state and (state.pair_67_avoid_left or 0)>0 then
  for _,choice in ipairs(choices) do
   if choice.key~=state.pair_67_avoid_direction then candidate=choice;break end
  end
  state.pair_67_avoid_left=state.pair_67_avoid_left-1
  if state.pair_67_avoid_left==0 then state.pair_67_avoid_direction=nil end
 end
 if holder==5 and target==8 and dx>0 and (not state or not state.right_suspended) then
  for _,choice in ipairs(choices) do if choice.key=="Right" then candidate=choice;break end end
 end
 if holder==6 and (target==2 or target==3) and candidate.key=="Right" then
  for _,choice in ipairs(choices) do if choice.key~="Right" then candidate=choice;break end end
 end
 if state and state.recovery_left and state.recovery_left>0 and state.recovery_direction then
  for _,choice in ipairs(choices) do if choice.key==state.recovery_direction then candidate=choice;break end end
 end
 if state then
  state.axis=candidate.axis
  state.direction=candidate.key
  state.geometry_reason=why
 end
 return {[candidate.key]=true},"approach_step",metrics
end
function M.interposition(sample)
 local a,b,c=find(sample,6),find(sample,2),find(sample,3)
 if not a or not b or not c then return nil end
 local ux,uy=b.x-a.x,b.y-a.y
 local den=ux*ux+uy*uy
 if den<1 then return nil end
 local t=((c.x-a.x)*ux+(c.y-a.y)*uy)/den
 local px=a.x+t*ux;local py=a.y+t*uy
 local lateral=math.sqrt((c.x-px)^2+(c.y-py)^2)
 return {between=t>0 and t<1,offset=lateral,projection=t,blocked=t>0 and t<1 and lateral<30}
end
function M.recover(state,measurement,holder,target)
 if holder==8 and target==9 then return false,"pair_8_9_no_blind_recovery" end
 if not state or not measurement or (state.recovery_used or 0)>=1 then return false,"no_recovery_available" end
 local keys={"Up","Down","Left","Right"}
 local best=nil;local best_gain=0
 for _,key in ipairs(keys) do
  local v=state.motion and state.motion[key]
  if not (holder==6 and (target==2 or target==3) and key=="Right") and
    not (holder==5 and target==8 and key=="Right" and state.right_suspended) and v and v.count>=1 then
   local dx=measurement.dx-v.dx;local dy=measurement.dy-v.dy
   local d=math.sqrt(dx*dx+dy*dy);local lat=math.min(math.abs(dx),math.abs(dy))
   local gain=M.score(measurement)-M.score({distance=d,lateral=lat})
   if gain>best_gain then best_gain=gain;best=key end
  end
 end
 if not best then
  -- Probe an alternative direction briefly; validate on the next neutral sample.
  for _,key in ipairs(keys) do
   if not (holder==6 and (target==2 or target==3) and key=="Right") and
    not (holder==5 and target==8 and key=="Right" and state.right_suspended) and key~=state.direction and key~=state.last_still_direction and (not state.motion or not state.motion[key] or state.motion[key].dx*({Right=1,Left=-1,Up=0,Down=0})[key]+state.motion[key].dy*({Up=-1,Down=1,Right=0,Left=0})[key]>=0) then
    best=key;break
   end
  end
  if not best then return false,"no_exploration_candidate" end
  state.recovery_exploratory=true
  state.recovery_phase="running"
 else state.recovery_exploratory=false end
 state.recovery_direction=best;state.recovery_left=state.recovery_exploratory and 4 or 16
 state.recovery_used=(state.recovery_used or 0)+1
 state.stalled=0;state.bad_bursts=0
 return true,best
end
function M.guard_diagonal(state,metrics)
 if not state or not state.diagonal_start or not metrics then return nil end
 local before=state.diagonal_start
 local growth=metrics.distance-before.distance
 local lateral_growth=metrics.lateral-before.lateral
 state.diagonal_trials=(state.diagonal_trials or 0)+1
 state.diagonal_start=nil
 if growth>5 or (growth>1 and lateral_growth>5) then
  state.diagonal_disabled=true
  state.penalties=state.penalties or {}
  state.penalties.Up=(state.penalties.Up or 0)+6
  state.penalties.Right=(state.penalties.Right or 0)+6
  return "diagonal_regression",growth,lateral_growth
 end
 if math.abs(growth)<0.5 and math.abs(lateral_growth)<0.5 then
  state.diagonal_still=(state.diagonal_still or 0)+1
  if state.diagonal_still>=2 then state.diagonal_disabled=true;return "diagonal_still",growth,lateral_growth end
 else state.diagonal_still=0 end
 return "diagonal_observed",growth,lateral_growth
end
-- Pair-specific feedback: RIGHT is preferred but never repeated blindly.
function M.guard_right(state,metrics,motion)
 if not state or not metrics or state.burst_direction~="Right" then return nil end
 if not state.burst_start then return nil end
 local distance_change=metrics.distance-state.burst_start.distance
 local actual_projection=motion and motion.projection or nil
 state.last_right_distance_change=distance_change
 if distance_change>8 or (actual_projection and actual_projection< -6) then
  -- 5→8: one adverse window can be inertia or a moving receiver.
  -- Demand three independent adverse bursts before a controlled retry.
  state.right_58_regressions=(state.right_58_regressions or 0)+1
  state.right_progress_streak=0
  if state.right_58_regressions>=3 then
   state.right_suspended=true
   state.right_block_reason="persistent_regression_58"
   return "right_persistent_regression",distance_change
  end
  return "right_transient_regression",distance_change
 end
 if distance_change>0 or (actual_projection and actual_projection<0) then
  state.right_small_negative=(state.right_small_negative or 0)+1
  state.right_cumulative_regression=(state.right_cumulative_regression or 0)+math.max(0,distance_change)
  if state.right_small_negative>=4 and state.right_cumulative_regression>12 then
   state.right_suspended=true;state.right_block_reason="repeated_regression"
   return "right_repeated_regression",distance_change
  end
  return "right_tolerated",distance_change
 end
 if distance_change< -0.5 or
    (math.abs(actual_projection or 0)<0.5 and
     (metrics.lateral < state.burst_start.lateral-0.5 or distance_change< -0.1)) then
  state.right_still=0
  state.right_58_regressions=0
  state.right_small_negative=0;state.right_cumulative_regression=0
  state.right_progress_streak=(state.right_progress_streak or 0)+1
  return (math.abs(actual_projection or 0)<0.5) and "right_lateral_progress" or "right_progress",distance_change
 end
 -- Horizontal stillness is diagnosed only after a sustained burst and
 -- neutral follow-up, not merely by tiny horizontal displacement.
 if actual_projection and math.abs(actual_projection)<0.5 then
  state.right_still=(state.right_still or 0)+1
  if state.right_still>=3 then
   state.right_suspended=true;state.right_block_reason="persistent_horizontal_still"
   return "right_still",distance_change
  end
  return "right_horizontal_still_pending",distance_change
 end
 state.right_still=(state.right_still or 0)+1
 if state.right_still>=2 then
  state.right_suspended=true
  state.right_block_reason="measured_still"
  return "right_still",distance_change
 end
 return "right_pending",distance_change
end
function M.capture(sample,holder,target)
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b then return nil end
 return {hx=a.x,hy=a.y,tx=b.x,ty=b.y}
end
function M.observe_motion(state,sample,holder,target)
 local before=state.burst_positions
 local now=M.capture(sample,holder,target)
 if not before or not now or not state.burst_direction then return "motion_unavailable" end
 local hx=now.hx-before.hx;local hy=now.hy-before.hy
 local tx=now.tx-before.tx;local ty=now.ty-before.ty
 local direction=state.burst_direction
 local expected={Right={1,0},Left={-1,0},Down={0,1},Up={0,-1},Up_Right={1,-1}}
 local ex=expected[direction]
 if not ex then return "motion_unavailable" end
 local projection=hx*ex[1]+hy*ex[2]
 local rx,ry=before.tx-before.hx,before.ty-before.hy
 local len=math.sqrt(rx*rx+ry*ry)
 local holder_toward=(len>0) and (hx*rx+hy*ry)/len or 0
 local receiver_away=(len>0) and (tx*rx+ty*ry)/len or 0
 state.last_motion={holder_dx=hx,holder_dy=hy,target_dx=tx,target_dy=ty,
  projection=projection,direction=direction,holder_toward=holder_toward,
  receiver_away=receiver_away,relative_closing=holder_toward-receiver_away}
 state.motion=state.motion or {}
 if math.abs(hx)+math.abs(hy)<0.5 then return "motion_delayed_or_still" end
 local old=state.motion[direction] or {dx=0,dy=0,count=0}
 local n=math.min(old.count+1,8)
 old.dx=(old.dx*old.count+hx)/(old.count+1)
 old.dy=(old.dy*old.count+hy)/(old.count+1)
 old.count=n;state.motion[direction]=old
 if projection< -0.5 then
  state.penalties=state.penalties or {}
  state.penalties[direction]=(state.penalties[direction] or 0)+12
  return "motion_opposite"
 end
 return "motion_calibrated"
end
function M.observe(state,metrics)
 if not metrics then return "no_metrics" end
 local d=metrics.distance
 local lateral=metrics.lateral
 if not state.initial_distance then state.initial_distance=d end
 if not state.best_distance or d<state.best_distance then state.best_distance=d end
 if not state.initial_lateral then state.initial_lateral=lateral end
 if not state.best_lateral or lateral<state.best_lateral then state.best_lateral=lateral end
 local result="progress_sample"
 if state.burst_start and state.burst_direction then
  local before=state.burst_start
  local gain=M.score(before)-M.score(metrics)
  local delta_distance=before.distance-d
  local delta_lateral=before.lateral-lateral
  local key=state.burst_direction
  state.penalties=state.penalties or {}
  state.tried=state.tried or {}
  state.tried[key]=true
  state.last_distance_gain=delta_distance
  state.last_lateral_gain=delta_lateral
  local combined_gain=delta_distance+math.max(-6,math.min(6,delta_lateral))*0.4
  if combined_gain>0.75 and delta_distance> -1.5 and delta_lateral> -5 then
   if state.last_good_direction==key then
    state.good_direction_streak=math.min(4,(state.good_direction_streak or 0)+1)
   else
    state.last_good_direction=key;state.good_direction_streak=1
   end
   state.good_direction_lock=math.min(3,state.good_direction_streak)
  elseif combined_gain< -1.5 then
   state.good_direction_lock=0;state.good_direction_streak=0
  end
  if delta_distance>0.5 or delta_lateral>0.5 then
   -- Partial improvement must not count as a bad burst even if weighted cost rose.
   state.penalties[key]=math.max(0,(state.penalties[key] or 0)-2)
   state.bad_bursts=0;state.zero_bursts=0;state.tried={}
   result="direction_partial_progress"
  elseif delta_distance< -0.5 and delta_lateral< -0.5 then
   -- Only penalize when BOTH dimensions regress.
   state.penalties[key]=(state.penalties[key] or 0)+8
   state.bad_bursts=(state.bad_bursts or 0)+1
   state.zero_bursts=0
   result="direction_worsened"
  else
   -- No detectable displacement may mean animation/latency: wait for samples.
   state.zero_bursts=(state.zero_bursts or 0)+1
   if state.zero_bursts>=3 then
    state.penalties[key]=(state.penalties[key] or 0)+3
    state.bad_bursts=(state.bad_bursts or 0)+1
    state.zero_bursts=0
    result="direction_no_progress"
   else
    result="direction_pending_feedback"
   end
  end
  if state.recovery_exploratory and state.recovery_phase=="awaiting_sample" then
   state.recovery_probe_gain=gain
   if delta_distance<=0.5 and delta_lateral<=0.5 then state.recovery_probe_failed=true end
  end
  if key=="Right" then state.right_bursts=(state.right_bursts or 0)+1 end
  state.last_gain=gain
  state.burst_start=nil
  state.burst_direction=nil
 end
 if state.previous_distance then
  if state.previous_distance-d>0.5 then
   state.recent_progress=math.min(3,(state.recent_progress or 0)+1)
  else state.recent_progress=0 end
  if d>=state.previous_distance-0.5 and lateral>=(state.previous_lateral or lateral)-0.5 then
   state.stalled=(state.stalled or 0)+1
  else state.stalled=0 end
 end
 state.previous_distance=d;state.previous_lateral=lateral
 if (state.bad_bursts or 0)>=8 then
  return "no_direction_improves"
 end
 return result
end
return M
