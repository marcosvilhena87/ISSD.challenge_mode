-- v0.8.23: progress-guided approach with bounded axis switching.
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.25",ROUTE={6,2,3,4,5,8,9,7,10,11},MAX_APPROACH=90,BURST_FRAMES=4,STALL_WINDOW=6}
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
function M.step(sample,holder,target,state)
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b or not sample.ball then return {},"missing_geometry" end
 local bx,by=sample.ball.x-a.x,sample.ball.y-a.y
 if bx*bx+by*by>18*18 then return {},"ball_not_at_feet" end
 local safe,why,metrics=Feet.check(sample,holder,target)
 if safe then return {},"target_in_range",metrics end
 if why~="too_far" and why~="diagonal_risk" then return {},why,metrics end
 local dx,dy=b.x-a.x,b.y-a.y
 local axis
 if why=="diagonal_risk" or (metrics and metrics.lateral>Feet.MAX_LATERAL) then
  -- Reduce the SMALLER component to reduce lateral error; avoid zero crossing.
  axis=math.abs(dx)<=math.abs(dy) and "x" or "y"
 else
  axis=(state and state.axis) or (math.abs(dx)>=math.abs(dy) and "x" or "y")
 end
 if state then state.axis=axis;state.geometry_reason=why end
 local key
 if why=="diagonal_risk" or (metrics and metrics.lateral>Feet.MAX_LATERAL) then
  if axis=="x" then key=dx>=0 and "Left" or "Right"
  else key=dy>=0 and "Up" or "Down" end
 else
  if axis=="x" then key=dx>=0 and "Right" or "Left"
  else key=dy>=0 and "Down" or "Up" end
 end
 return {[key]=true},"approach_step",metrics
end
function M.observe(state,metrics)
 if not metrics then return "no_metrics" end
 local d=metrics.distance
 if not state.initial_distance then state.initial_distance=d end
 if not state.best_distance or d<state.best_distance then state.best_distance=d end
 local lateral=metrics.lateral
 if not state.initial_lateral then state.initial_lateral=lateral end
 if not state.best_lateral or lateral<state.best_lateral then state.best_lateral=lateral end
 if state.previous_distance then
  if d>=state.previous_distance-0.5 and lateral>=(state.previous_lateral or lateral)-0.5 then
   state.stalled=(state.stalled or 0)+1
  else state.stalled=0 end
 end
 state.previous_distance=d;state.previous_lateral=lateral
 if (state.stalled or 0)>=M.STALL_WINDOW then
  state.stalled=0
  state.switches=(state.switches or 0)+1
  state.axis=state.axis=="x" and "y" or "x"
  return "axis_switched"
 end
 return "progress_sample"
end
return M
