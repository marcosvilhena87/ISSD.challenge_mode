package.path="lua/?.lua;lua/?/init.lua;"..package.path
local W=require("challenge.dribble_waypoints_v022")
local O=require("challenge.dribble_route_optimization_v035")
local x=W.waypoints[1][1]
assert(O.apply("FLAG1_X_MINUS_4"))
assert(W.waypoints[1][1]==x-4)
assert(O.apply("CONTROL"))
assert(W.waypoints[1][1]==x)
assert(not O.apply("BAD_PROFILE"))
local route={complete=true,discontinuities=0,observations={}}
local base={173,244,204,172,192}
for i=1,5 do route.observations[i]={number=i,segment_frames=base[i],start_basis=i==1 and "active_candidate" or "previous_flag",valid_start=true} end
local a=O.result(route,"CONTROL",{classification="contextual_goal_candidate"})
assert(a.active_frames==985 and a.baseline_delta==-3 and a.eligible==1)
local b=O.result(route,"CONTROL",{classification="no_increment_unverified"})
assert(b.eligible==0)
print("DRIBBLE route optimization v035 tests PASS")
