package.path="lua/?.lua;lua/?/init.lua;"..package.path
local E=require("challenge.goal_counter_evidence_v3")
local function q() return {positive=0,plausible=0,inconsistent=0,invalid=0,resets=0,visual=false,negative=false} end
local a=q();a.positive=1;a.plausible=1;a.visual=true
assert(E.classify(a)=="correlated_goal_candidate")
a.negative=true
assert(E.classify(a)=="conflict_increment_with_negative_control")
local b=q();b.negative=true
assert(E.classify(b)=="negative_control_no_increment")
local c=q();c.visual=true
assert(E.classify(c)=="visual_goal_without_increment")
local d=q();d.resets=1
assert(E.quality(d)=="reset_or_wrap_observed")
print("goal counter evidence v3 tests passed")
