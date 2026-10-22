package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_goal_v0323")
local function snap(f,x,y,bx,by)
 return {frame=f,gs=0,ptr=0x0F00,remaining=5,px=x or 376,py=y or 320,
 bx=bx or 376,by=by or 320,poss=0x0F00}
end
local st=P.new();local buttons,why
local start=nil
for i=1,130 do
 buttons,st,why=P.step(snap(i),st)
 if st.event=="delayed_observation_started" then start=i;break end
end
assert(start and why=="delayed_observation")
buttons,st,why=P.step(snap(start+1,376,320,380,320),st)
assert(why=="delayed_observation" and st.observation.ball_moved)
buttons,st,why=P.step(snap(start+2,379,320,380,320),st)
assert(why=="movement_detected" and st.event=="delayed_player_movement")
assert(st.base.recoveries==0 and st.detected_delays==1)
-- Observe a full window where only ball moved. It must NOT claim player recovered.
st=P.new();start=nil
for i=1,130 do
 buttons,st,why=P.step(snap(i),st)
 if st.event=="delayed_observation_started" then start=i;break end
end
assert(start)
for i=start+1,start+18 do
 buttons,st,why=P.step(snap(i,376,320,380,320),st)
end
assert(why=="movement_observed_ball_only" and st.event=="delayed_ball_only")
-- Schema regressions are enforced in the runner trace header separately.
print("DRIBBLE v0.3.2.3 delayed movement synthetic tests OK")
