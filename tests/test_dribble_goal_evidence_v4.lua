package.path="lua/?.lua;lua/?/init.lua;"..package.path
local E=require("challenge.dribble_goal_evidence_v4")
local function s(f,g,n,gs) return {frame=f,goal=g,lo=g%256,hi=math.floor(g/256),remaining=n,gs=gs or 0,ptr=0x0F00} end
local q=E.new(s(100,3,5))
for n=4,1,-1 do E.step(q,s(105+(4-n)*10,3,n)) end
assert(E.step(q,s(150,3,0))=="fifth_flag_observed")
E.marker(q,"BEFORE_SHOT",170)
assert(E.step(q,s(190,4,0,5))=="goal_counter_increment")
assert(E.classify(q)=="contextual_goal_candidate")
E.marker(q,"GOAL_VISUAL_CONFIRMED",200)
assert(E.classify(q)=="contextual_goal_correlated_visual")
local z=E.new(s(100,4,5))
E.step(z,s(110,5,5,5))
assert(E.classify(z)=="increment_outside_validated_dribble_context")
local x=E.new(s(100,5,5));E.marker(x,"SHOT_MISSED",120)
assert(E.classify(x)=="negative_control_no_increment")
print("Goal evidence v4 synthetic tests passed")
