package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_goal_v0322")
local function s(frame,x,y)
 return {frame=frame,gs=0,ptr=0x0F00,remaining=5,px=x or 376,py=y or 320,
 bx=376,by=320,poss=0x0F00}
end
local st=P.new();local buttons,why
for i=1,46 do buttons,st,why=P.step(s(i),st) end
assert(why=="stuck_recovery" and st.event=="stuck_recovery_started")
assert(st.recovery.direction=="Up") -- first waypoint lies above player
buttons,st,why=P.step(s(47),st)
assert(buttons.Up and st.diag:find("probing",1,true))
buttons,st,why=P.step(s(48,376,316),st)
assert(why=="recovery_completed" and st.event=="stuck_recovered" and st.recoveries==0)
buttons,st,why=P.step(s(49,376,316),st)
assert(why=="waypoint")
st=P.new()
for i=1,150 do
 buttons,st,why=P.step(s(i),st)
 if why=="stuck_recovery_exhausted" then break end
end
assert(why=="stuck_recovery_exhausted" and st.recoveries==2)
assert(st.last_recovery:find("probe_failed",1,true))
print("DRIBBLE v0.3.2.2 diagnostics tests OK")
