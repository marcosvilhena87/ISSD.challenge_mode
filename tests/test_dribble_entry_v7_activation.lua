-- Static/config regression: entry command accepted on ARM.
package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local W=require("challenge.dribble_waypoints_v022")
W.set_entry_v7(true)
assert(W.entry_v7==true)
local f=W.new()
local snapshot={frame=1,gs=0,ptr=0x0F00,remaining=4,px=700,py=320,bx=700,by=320,poss=0x0F00}
local buttons=W.step(snapshot,f)
assert(buttons.Right)
W.set_entry_v7(false)
assert(W.entry_v7==false)
print("test_dribble_entry_v7_activation OK")
