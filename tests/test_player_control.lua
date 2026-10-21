package.path="lua/?.lua;lua/?/init.lua;"..package.path
local C=require("challenge.player_control")
local calls={dribble=0,passing=0}
local policies={
 DRIBBLE={decide=function() calls.dribble=calls.dribble+1;return {Right=true},"advance" end},
 PASS={decide=function() calls.passing=calls.passing+1;return {B=true},"pass" end}
}
local b,r=C.decide("DRIBBLE",{}, {armed=false},policies)
assert(r=="disarmed" and not next(b) and calls.dribble==0)
b,r=C.decide("DRIBBLE",{}, {armed=true,started=0},policies)
assert(r=="advance" and b.Right and calls.dribble==1 and calls.passing==0)
b,r=C.decide("PASS",{}, {armed=true},policies)
assert(r=="pass" and b.B and calls.passing==1 and calls.dribble==1)
b,r=C.decide("SHOOT",{}, {armed=true},policies)
assert(r=="unknown_challenge" and not next(b) and C.should_disarm(r))
b,r=C.decide("PASS",{}, {armed=true},{PASS={decide=function() return {Bad=true},"oops" end}})
assert(r=="invalid_buttons" and not next(b))
b,r=C.decide("PASS",{}, {armed=true},{PASS={decide=function() error("boom") end}})
assert(r=="policy_error" and not next(b))
assert(C.should_disarm("not_playing") and C.should_disarm("invalid_read"))
assert(not C.should_disarm("seek_ball") and not C.should_disarm("advance_right"))
print("test_player_control.lua OK synthetic")
