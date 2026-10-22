-- v0.3.5 route experiments: combined route is default, CONTROL restores historical reference.
local W=require("challenge.dribble_waypoints_v022")
local M={}
M.BASELINE={176,244,204,172,192}
M.DEFAULT_PROFILE="FLAG2_760_330_FLAG5_1460_360"
M.names={"CONTROL","FLAG1_X_MINUS_4","FLAG2_X_PLUS_4","FLAG2_760_325","FLAG2_760_330_FLAG5_1460_360","FLAG3_Y_MINUS_4","FLAG4_X_MINUS_4","FLAG5_X_MINUS_4"}
local originals={}
local historical={{555,261},{772,304},{974,356},{1228,293},{1450,367}}
for i,p in ipairs(historical) do originals[i]={p[1],p[2]} end
local changes={FLAG1_X_MINUS_4={1,-4,0},FLAG2_X_PLUS_4={2,4,0},FLAG2_760_325={2,-12,21},
 FLAG2_760_330_FLAG5_1460_360={{2,-12,26},{5,10,-7}},FLAG3_Y_MINUS_4={3,0,-4},FLAG4_X_MINUS_4={4,-4,0},FLAG5_X_MINUS_4={5,-4,0}}
function M.apply(name)
 local change=name=="CONTROL" and nil or changes[name]
 if name~="CONTROL" and not change then return false,"unknown_profile" end
 for i,p in ipairs(originals) do
  W.waypoints[i][1]=p[1];W.waypoints[i][2]=p[2]
 end
 if change then
  local edits=type(change[1])=="table" and change or {change}
  for _,edit in ipairs(edits) do
   local p=W.waypoints[edit[1]]
   p[1]=p[1]+edit[2];p[2]=p[2]+edit[3]
  end
 end
 return true
end
function M.rows(route,profile,goal)
 local result={}
 local observed=route and route.observations or {}
 for i=1,5 do
  local r=observed and observed[i]
  result[i]={profile=profile,flag=i,frames=r and r.segment_frames,
    reference=M.BASELINE[i],delta=r and r.segment_frames-M.BASELINE[i],
    valid=r and r.valid_start and r.start_basis=="active_candidate" or i>1 and r~=nil,
    px=r and r.px,py=r and r.py}
 end
 return result
end
function M.result(route,profile,goal)
 local complete=route and route.complete and route.discontinuities==0
 local valid=complete
 local total=0
 if valid then
  for i=1,5 do
   local v=route.observations[i]
   if not v or (i==1 and (v.start_basis~="active_candidate" or not v.valid_start)) then valid=false;break end
   total=total+v.segment_frames
  end
 end
 local cls=goal and goal.classification or "unverified"
 local contextual=(cls=="contextual_goal_candidate" or cls=="contextual_goal_correlated_visual")
 return {complete=valid and 1 or 0,active_frames=valid and total or nil,
  baseline_delta=valid and total-988 or nil,
  goal_classification=cls,eligible=valid and contextual and 1 or 0,
  verdict=not valid and "incomplete_route" or not contextual and "goal_not_contextual" or
   (total<985 and "faster_than_last_observed" or total==985 and "matches_last_observed" or "slower_than_last_observed")}
end
return M
