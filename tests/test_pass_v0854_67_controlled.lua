-- Controlled isolated check: run from repository root with Lua 5.3+.
package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local Ordered=require("challenge.pass_ordered_v0820")
local Feet=require("challenge.pass_feet_v0815")
local function case(hx,hy,tx,ty,expected)
 local sample={ball={x=hx,y=hy},players={
  {id=6,x=hx,y=hy},{id=7,x=tx,y=ty}}}
 local state={}
 local keys,reason=Ordered.step(sample,6,7,state)
 assert(reason=="approach_step","unexpected reason: "..tostring(reason))
 assert(keys.Up==true and keys.Right==true,expected or "expected UP+RIGHT")
 assert(not keys.B,"approach must not press pass B")
end
-- Receiver is above/right and lateral error requires adjustment.
case(150,300,270,170,"above-right case failed")
print("PASS: 6→7 UP+RIGHT geometry test")
