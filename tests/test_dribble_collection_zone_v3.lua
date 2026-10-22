package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local Z=require("challenge.dribble_collection_zone_v3")
local W=require("challenge.dribble_waypoints_v022")
local wp=W.waypoints[2]
for _,name in ipairs({"LEFT","ABOVE","BELOW"}) do
 local x,y,phase=Z.target(name,wp,{px=600,py=280},{done=false})
 assert(phase=="staging" and x==wp[1]-42)
 if name=="ABOVE" then assert(y==wp[2]-22) end
 if name=="BELOW" then assert(y==wp[2]+22) end
end
local stage={done=false}
local x,y,phase=Z.target("LEFT",wp,{px=wp[1]-42,py=wp[2]},stage)
assert(phase=="final" and stage.done)
assert(Z.direction({pre_x=742,pre_y=329,post_x=744,post_y=329})=="right")
local function snap() return {frame=1,gs=0,ptr=0x0F00,remaining=4,px=600,py=280,bx=600,by=280,poss=0x0F00} end
W.set_zone_approach("ABOVE")
local buttons,_,reason=W.step(snap(),W.new())
assert(reason=="waypoint" and buttons.Right and buttons.Down and not buttons.Y)
W.set_zone_approach(nil)
local default,_,r=W.step(snap(),W.new())
assert(r=="waypoint" and default.Right)
print("test_dribble_collection_zone_v3 OK")
