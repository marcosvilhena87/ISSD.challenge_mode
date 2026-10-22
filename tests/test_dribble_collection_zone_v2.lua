package.path="./lua/?.lua;./lua/?/init.lua;"..package.path
local Z=require("challenge.dribble_collection_zone_v2")
local w={{555,261},{760,330},{974,356},{1228,293},{1460,360}}
local st=Z.new()
local function s(f,r,x,y) return {frame=f,remaining=r,px=x,py=y} end
assert(#Z.observe(st,s(10,4,742,327),w)==1) -- near, no change
Z.observe(st,s(11,4,746,328),w)
local e=Z.observe(st,s(12,3,748,329),w)
assert(#e==1 and e[1].kind=="collection_transition")
local c=e[1].record
assert(c.flag==2 and c.pre_x==746 and c.post_x==748 and c.pre_frame==11)
assert(#c.window>=1 and c.pre_distance>0)
-- Counter discontinuities must never be interpreted as collection.
local t=Z.new()
Z.observe(t,s(1,5,540,260),w)
local j=Z.observe(t,s(2,3,550,260),w)
for _,v in ipairs(j) do assert(v.kind~="collection_transition") end
-- A frame gap cannot justify inferring the time/position of collection.
local u=Z.new()
Z.observe(u,s(1,4,740,330),w)
local gap=Z.observe(u,s(10,3,745,330),w)
for _,v in ipairs(gap) do assert(v.kind~="collection_transition") end
print("test_dribble_collection_zone_v2 OK")
