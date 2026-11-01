-- v0.8.23: progress-guided approach with bounded axis switching.
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.30",ROUTE={6,2,3,4,5,8,9,7,10,11},MAX_APPROACH=90,MAX_APPROACH_ABSOLUTE=210,EXTEND_FRAMES=30,BURST_FRAMES=4,STALL_WINDOW=6}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.next(_,holder,visited)
 visited=visited or {}
 if not holder or holder<2 or holder>11 then return nil,"invalid_holder" end
 for _,id in ipairs(M.ROUTE) do
  if id~=holder and not visited[id] then return id,"ordered_remaining" end
 end
 return nil,"all_visited"
end
function M.can_extend(state,frames,measurement)
 if frames>=M.MAX_APPROACH_ABSOLUTE or not measurement then return false,"absolute_limit_or_missing_measurement" end
 if not state or type(state.initial_distance)~="number" or type(state.best_distance)~="number" then return false,"insufficient_progress_evidence" end
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
function M.step(sample,holder,target,state)
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b or not sample.ball then return {},"missing_geometry" end
 local bx,by=sample.ball.x-a.x,sample.ball.y-a.y
 if bx*bx+by*by>18*18 then return {},"ball_not_at_feet" end
 local safe,why,metrics=Feet.check(sample,holder,target)
 if safe then return {},"target_in_range",metrics end
 if why~="too_far" and why~="diagonal_risk" then return {},why,metrics end
 local dx,dy=metrics.dx,metrics.dy
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
 if state then
  state.axis=candidate.axis
  state.direction=candidate.key
  state.geometry_reason=why
 end
 return {[candidate.key]=true},"approach_step",metrics
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
 local expected={Right={1,0},Left={-1,0},Down={0,1},Up={0,-1}}
 local ex=expected[direction]
 if not ex then return "motion_unavailable" end
 local projection=hx*ex[1]+hy*ex[2]
 state.last_motion={holder_dx=hx,holder_dy=hy,target_dx=tx,target_dy=ty,projection=projection,direction=direction}
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
  state.last_gain=gain
  state.burst_start=nil
  state.burst_direction=nil
 end
 if state.previous_distance then
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
