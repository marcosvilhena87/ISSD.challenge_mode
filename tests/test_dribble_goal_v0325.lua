package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_goal_v0325")
local function s(f)
 return {frame=f,gs=0,ptr=0x0F00,remaining=5,
 px=f>=28 and 380 or 376,py=320,bx=f>=24 and 392 or 388,by=319,
 poss=0x0F00,time=f>=61 and 29 or 30}
end
local st=P.new()
for i=1,91 do
 local buttons,reason
 buttons,st,reason=P.step(s(i),st)
end
assert(st.sync_result and st.sync_result.arm==1)
assert(st.sync_result.first_ball==24 and st.sync_result.first_player==28)
assert(st.sync_result.timer_change==61)
assert(st.sync_result.clock_status=="clock_transition_observed")
assert(st.base.calibration_result and st.base.calibration_result.first_player==28)
print("DRIBBLE v0.3.2.5 start synchronization synthetic OK")
