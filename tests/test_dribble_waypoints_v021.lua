package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_waypoints_v021")
local s={frame=100,gs=0,ptr=0x0F00,remaining=5,px=376,py=320,bx=388,by=320,poss=0x0F00}
local st=P.new()
local b,why
b,st,why=P.step(s,st)
assert(why=="waypoint" and b.Right and b.Up)
-- At the v0.2 stopping point the v0.2.1 controller must KEEP trying.
s.frame=104;s.px=547;s.py=265
b,st,why=P.step(s,st)
assert(why=="precision_approach" and b.Right)
s.frame=151
b,st,why=P.step(s,st)
assert(why=="local_search")
s.frame=152
b,st,why=P.step(s,st)
assert(why=="local_search")
-- A real decrement must switch waypoints even before geometrically reaching the center.
s.frame=160;s.remaining=4
b,st,why=P.step(s,st)
assert(st.target==2 and (why=="waypoint" or why=="precision_approach"))
-- Completion and impossible jumps terminate.
s.frame=170;s.remaining=0
b,st,why=P.step(s,st)
assert(why=="counter_discontinuity" and not next(b))
st=P.new();s.frame=200;s.remaining=0
b,st,why=P.step(s,st)
assert(why=="five_collected" and not next(b))
st=P.new();s.frame=300;s.gs=6;s.remaining=5
b,st,why=P.step(s,st)
assert(why=="not_playing")
print("test_dribble_waypoints_v021.lua OK synthetic")
