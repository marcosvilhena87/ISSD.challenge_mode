package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_waypoints_v02")
local s={frame=100,gs=0,ptr=0x0F00,remaining=5,px=376,py=320,bx=388,by=320,poss=0x0F00}
local st=P.new()
local buttons;local reason
buttons,st,reason=P.step(s,st)
assert(reason=="waypoint" and buttons.Right and buttons.Up and st.target==1)
s.remaining=4;s.frame=110;s.px=555;s.py=261
buttons,st,reason=P.step(s,st)
assert(st.target==2 and reason=="waypoint" and buttons.Right and buttons.Down)
s.frame=111;s.px=772;s.py=304
buttons,st,reason=P.step(s,st)
assert(reason=="await_collection" and not next(buttons))
s.frame=203
buttons,st,reason=P.step(s,st)
assert(reason=="waypoint_not_collected")
s.frame=210;s.remaining=0
buttons,st,reason=P.step(s,st)
assert(reason=="counter_jump" and not next(buttons))
st=P.new();s.frame=400;s.remaining=0
buttons,st,reason=P.step(s,st)
assert(reason=="five_collected" and not next(buttons))
st=P.new();s.remaining=5;s.frame=500;s.gs=6
buttons,st,reason=P.step(s,st)
assert(reason=="not_playing" and not next(buttons))
print("test_dribble_waypoints_v02.lua OK synthetic")
