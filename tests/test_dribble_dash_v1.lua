package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local D=require("challenge.dribble_dash_v1")
local wp={{555,261},{760,330},{974,356},{1228,293},{1460,360}}
local function sample(px,py,bx,by,poss,remaining)
 return {gs=0,ptr=0x0F00,remaining=remaining or 4,px=px,py=py,bx=bx,by=by,poss=poss or 0x0F00}
end
local b,ok=D.apply({Right=true},sample(550,330,552,331), "waypoint",wp)
assert(ok and b.Right and b.Y,"dash on long safe waypoint")
local b2,ok2=D.apply({Right=true,Y=true},sample(690,330,690,330),"waypoint",wp)
assert(not ok2 and not b2.Y,"dash off near target")
local b3,ok3=D.apply({Right=true,Y=true},sample(550,330,610,330),"recover_ball",wp)
assert(not ok3 and not b3.Y,"dash off in ball recovery")
local b4,ok4=D.apply({Right=true,B=true,Y=true},sample(550,330,550,330),"shot_charge",wp)
assert(not ok4 and not b4.Y and b4.B,"shot input unchanged")
local b5,ok5=D.apply({Right=true,Y=true},sample(550,330,550,330),"waypoint",wp)
b5,ok5=D.apply(b5,sample(690,330,690,330),"precision_approach",wp)
assert(not ok5 and not b5.Y,"no sticky dash")
print("test_dribble_dash_v1 OK")
