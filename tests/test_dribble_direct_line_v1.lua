package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local W=require("challenge.dribble_waypoints_v022")
local O=require("challenge.dribble_route_optimization_v035")
assert(O.apply(O.DEFAULT_PROFILE))
W.travel_profile="DIRECT_LINE"
local function s(f,x,y,remaining)
 return {frame=f,gs=0,ptr=0x0F00,remaining=remaining or 4,px=x,py=y,bx=x,by=y,poss=0x0F00}
end
local st=W.new()
local b,_,reason=W.step(s(1,600,280),st)
assert(reason=="waypoint" and b.Right and st.line and st.line.tx==760)
local bx,_,why=W.step(s(2,650,305),st)
assert(why=="waypoint" and bx.Right)
local br,_,r=W.step(s(3,650,305,3),st)
assert(r=="waypoint" and st.line and st.line.tx==974,"new flag resets line")
local bp,_,rp=W.step(s(4,961,350,3),st)
assert(rp=="precision_approach" and not bp.Y,"precision remains independent")
print("test_dribble_direct_line_v1 OK")
