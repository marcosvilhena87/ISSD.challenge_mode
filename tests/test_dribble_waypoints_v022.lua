package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_waypoints_v022")
local s={frame=100,gs=0,ptr=0x0F00,remaining=5,px=553,py=262,bx=568,by=262,poss=0x0F00}
local st=P.new()
local b,why;b,st,why=P.step(s,st)
assert(why=="precision_approach")
s.frame=101;s.remaining=4
b,st,why=P.step(s,st)
assert(st.target==2 and st.event=="flag_collected" and st.motion_frame==101 and st.grace_until==161)
-- No displacement in the old window must not trigger stuck directly after collection.
for f=102,161 do s.frame=f;b,st,why=P.step(s,st);assert(why~="stuck","false stuck in grace") end
assert(st.event==nil)
-- After grace, deliberate sustained movement without displacement SHOULD trip safety.
local stuck=false
for f=162,270 do s.frame=f;b,st,why=P.step(s,st);if why=="stuck" then stuck=true;break end end
assert(stuck,"stuck watchdog should remain active")
-- Counter reset and completion guards.
st=P.new();s.frame=300;s.remaining=0
b,st,why=P.step(s,st);assert(why=="five_collected")
st=P.new();s.frame=400;s.gs=6
b,st,why=P.step(s,st);assert(why=="not_playing")
print("test_dribble_waypoints_v022.lua OK synthetic")
