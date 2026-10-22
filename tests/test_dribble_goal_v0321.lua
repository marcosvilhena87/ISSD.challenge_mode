package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_goal_v0321")
local function sample(frame)
 return {frame=frame,gs=0,ptr=0x0F00,remaining=5,px=377,py=319,bx=377,by=319,poss=0x0F00}
end
local st=P.new();local b,reason
for i=1,46 do b,st,reason=P.step(sample(i),st) end
assert(reason=="stuck_recovery" and st.event=="stuck_recovery_started")
local s=sample(47);b,st,reason=P.step(s,st);assert(reason=="stuck_recovery")
s=sample(48);s.py=323;b,st,reason=P.step(s,st)
assert(reason=="recovery_completed" and st.event=="stuck_recovered")
s=sample(49);s.py=323;b,st,reason=P.step(s,st)
assert(reason=="waypoint" and st.phase=="flags")
-- Separate attempt: two bounded probes eventually disarm.
st=P.new();local last=nil
for i=1,240 do
 b,st,last=P.step(sample(i),st)
 if last=="stuck_recovery_exhausted" then break end
end
assert(last=="stuck_recovery_exhausted" and st.recoveries==2)
print("DRIBBLE v0.3.2.1 recovery synthetic tests OK")
