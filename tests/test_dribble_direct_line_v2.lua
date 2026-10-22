package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local W=require("challenge.dribble_waypoints_v022")
local C=require("challenge.dribble_direct_line_calibration_v2")
W.travel_profile="DIRECT_LINE"
local function s(f,x,y) return {frame=f,gs=0,ptr=0x0F00,remaining=4,px=x,py=y,bx=x,by=y,poss=0x0F00} end
local st=W.new()
local b,_,reason=W.step(s(1,600,280),st)
assert(reason=="waypoint" and b.Right and b.Down,"diagonal must be available")
local c=C.new()
local o=C.observe(c,s(1,600,280),reason,b,st.line)
assert(o and o.diagonal==1)
local r=C.summary(c,2)
assert(r.frames==1 and r.diagonal==1 and r.maximum==0)
local b2,_,r2=W.step(s(2,670,330),st)
assert(r2=="waypoint" and not b2.Y)
print("test_dribble_direct_line_v2 OK")
