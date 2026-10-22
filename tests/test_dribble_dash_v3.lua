package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local D=require("challenge.dribble_dash_v3")
local st=D.new()
local wp={{555,261},{760,330},{974,356},{1228,293},{1460,360}}
local function run(f,x,reason,poss,bx)
 local s={frame=f,px=x,py=330,bx=bx or x,by=330,gs=0,ptr=0x0F00,remaining=4,poss=poss or 0x0F00}
 return D.step(st,{Right=true},s,reason or "waypoint",wp)
end
local _,on=run(1,550);assert(on)
local _,off,events=run(2,560,"precision_approach")
assert(not off and events[1].cause=="precision_approach")
local _,on2=run(3,550);assert(on2)
local _,off2,events2=run(4,630,"waypoint")
assert(not off2 and events2[1].cause=="braking_distance")
assert(D.flag_summary(st,2,7).frames_since_off==3)
print("test_dribble_dash_v3 OK")
