package.path="lua/?.lua;lua/?/init.lua;"..package.path
local E=require("challenge.dribble_goal_evidence_v4")
local function snap(f,g,n,gs)
 return {frame=f,goal=g,lo=g%256,hi=math.floor(g/256),remaining=n,gs=gs or 0,ptr=0x0F00}
end
local a=E.new(snap(100,4,5))
for i=4,1,-1 do E.step(a,snap(110+(4-i)*10,4,i)) end
E.step(a,snap(150,4,0))
E.marker(a,"SHOT_STARTED",180)
E.step(a,snap(200,5,0,5))
assert(E.classify(a)=="contextual_goal_candidate")
assert(a.increment_frame==200 and a.shot_frame==180)
local b=E.new(snap(100,5,5))
E.step(b,snap(150,6,5,5))
assert(E.classify(b)=="increment_outside_validated_dribble_context")
local c=E.new(snap(100,6,5))
E.marker(c,"SHOT_MISSED",200)
assert(E.classify(c)=="negative_control_no_increment")
print("DRIBBLE v0.3.3 goal integration contract OK")
