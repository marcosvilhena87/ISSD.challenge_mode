-- Pure benchmark calculations; all timings in emulated frames.
local M={}
function M.calculate(a,goal,active,route)
 local ff=goal.flags_frame or a.flags_frame
 local sf=goal.shot_frame or a.shot_frame
 local gf=goal.increment_frame
 local af=active and active.active_frame
 local function elapsed(x,y) if type(x)=="number" and type(y)=="number" and x>=y then return x-y end end
 local stages={
  arm_to_active=elapsed(af,a.started),
  active_to_fifth=elapsed(ff,af),
  arm_to_fifth=elapsed(ff,a.started),
  fifth_to_shot=elapsed(sf,ff),
  shot_to_increment=elapsed(gf,sf),
  fifth_to_increment=elapsed(gf,ff),
  arm_to_increment=elapsed(gf,a.started),
  route_comparable=route and route.comparable and 1 or 0,
  route_delta=route and route.comparable and route.delta_total or nil
 }
 return stages
end
return M
