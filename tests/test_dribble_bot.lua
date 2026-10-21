package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_bot")
local s={frame=10,game_state=0,ptr=0x0F00,possession=0x0F00,player_x=100,player_y=200,ball_x=100,ball_y=200,field_length=2048}
local b,reason=P.decide(s,{started=0})
assert(reason=="advance_right" and b.Right)
s.possession=0;s.ball_x=200
b,reason=P.decide(s,{started=0});assert(reason=="seek_ball" and b.Right)
s.ball_x=0;b,reason=P.decide(s,{started=0});assert(b.Left)
s.ptr=0;b,reason=P.decide(s,{started=0});assert(reason=="not_playing" and not next(b))
s.ptr=0x0F00;s.frame=1800;b,reason=P.decide(s,{started=0});assert(reason=="time_budget" and not next(b))
s.frame=20;s.player_x=nil;b,reason=P.decide(s,{started=0});assert(reason=="invalid_read")
print("test_dribble_bot.lua OK synthetic")
