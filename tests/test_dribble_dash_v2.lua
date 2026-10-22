package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local D=require("challenge.dribble_dash_v2")
local wp={{555,261},{760,330},{974,356},{1228,293},{1460,360}}
local st=D.new()
local function tick(frame,x,reason,ball,poss)
 local s={frame=frame,px=x,py=330,bx=ball or x,by=330,gs=0,ptr=0x0F00,remaining=4,poss=poss or 0x0F00}
 return D.step(st,{Right=true},s,reason or "waypoint",wp)
end
local b,on=tick(1,550)
assert(on and b.Y)
local _,on2=tick(2,562)
assert(on2)
local b3,on3,e3,m=tick(3,574)
assert(not on3 and not b3.Y and m.brake>60,"adaptive braking must release dash early")
local b4,on4=tick(4,680,"precision_approach")
assert(not on4 and not b4.Y)
local b5,on5=tick(5,550,"recover_ball")
assert(not on5 and not b5.Y)
local b6,on6=tick(6,550,"waypoint",620)
assert(not on6 and not b6.Y)
assert(st.frames[2]==2 and st.starts[2]==1 and st.stops[2]==1)
print("test_dribble_dash_v2 OK")
