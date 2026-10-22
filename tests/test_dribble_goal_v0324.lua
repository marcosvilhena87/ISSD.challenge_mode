package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_goal_v0324")
local function s(f,px,py,bx,by)
 return {frame=f,gs=0,ptr=0x0F00,remaining=5,px=px or 376,py=py or 320,
 bx=bx or 376,by=by or 320,poss=0x0F00}
end
local st=P.new();local buttons,reason
for i=1,91 do
 local bx=i>=20 and 382 or 376
 local px=i>=70 and 382 or 376
 buttons,st,reason=P.step(s(i,px,320,bx,320),st)
 if i==46 then assert(reason~="stuck_recovery" and not st.base.base.recovery) end
end
assert(st.calibration_done)
assert(st.calibration_result.first_ball==20)
assert(st.calibration_result.first_player==70)
assert(st.calibration_result.classification=="player_moved")
assert(st.calibration_result.finish==91)
assert(st.calibration_result.first_possession_change==nil)
local second=P.new()
for i=1,92 do buttons,second,reason=P.step(s(i),second) end
assert(second.calibration_done and second.calibration_result.classification=="no_motion")
print("DRIBBLE v0.3.2.4 initial calibration OK")
