-- Pure-Lua regression for the reversible DRIBBLE approach policy.
-- Run at repository root with: lua tests/test_dribble_approach_v035.lua
package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local W=require("challenge.dribble_waypoints_v022")
local O=require("challenge.dribble_route_optimization_v035")
local function s(frame,px,py,poss,bx,by)
 return {frame=frame,gs=0,ptr=0x0F00,remaining=4,px=px,py=py,
  bx=bx or px,by=by or py,poss=poss or 0x0F00}
end
local function hasmove(b) return b.Left or b.Right or b.Up or b.Down end
local function run(profile,frame,px,py,poss,bx,by)
 W.approach_profile=profile
 local st=W.new()
 local b,_,reason=W.step(s(frame,px,py,poss,bx,by),st)
 return b,reason
end
assert(O.apply("CONTROL"))
assert(W.waypoints[2][1]==772 and W.waypoints[2][2]==304)
local b0,r0=run("CONTROL",101,755,300)
local b1,r1=run("CONTINUOUS_PRECISION",101,755,300)
assert(r0=="precision_approach" and r1=="precision_approach")
assert(not hasmove(b0),"CONTROL must retain 1-in-4 precision pulses")
assert(hasmove(b1),"continuous precision must move when outside deadzone")
local br0,rr0=run("CONTROL",101,700,250,0,750,280)
local br1,rr1=run("CONTINUOUS_PRECISION",101,700,250,0,750,280)
assert(rr0=="recover_ball" and rr1=="recover_ball")
assert(br0.Right==br1.Right and br0.Down==br1.Down,
 "ball recovery must be unchanged")
assert(O.apply("FLAG2_760_325"))
assert(W.waypoints[2][1]==760 and W.waypoints[2][2]==325)
assert(O.apply("CONTROL"))
assert(W.waypoints[2][1]==772 and W.waypoints[2][2]==304)
W.approach_profile="CONTROL"
print("PASS: reversible approach, recovery invariant, waypoint restore")
