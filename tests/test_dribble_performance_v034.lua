package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_performance_v034")
local a={started=100}
local g={flags_frame=1133,shot_frame=1215,increment_frame=1362}
local v=P.calculate(a,g,{active_frame=150},{comparable=true,delta_total=-3})
assert(v.arm_to_active==50)
assert(v.active_to_fifth==983)
assert(v.arm_to_fifth==1033)
assert(v.fifth_to_shot==82)
assert(v.shot_to_increment==147)
assert(v.fifth_to_increment==229)
assert(v.arm_to_increment==1262)
assert(v.route_comparable==1 and v.route_delta==-3)
local missing=P.calculate(a,{flags_frame=1133},{active_frame=150},{comparable=false})
assert(missing.shot_to_increment==nil and missing.route_delta==nil)
print("DRIBBLE performance v034 PASS")
