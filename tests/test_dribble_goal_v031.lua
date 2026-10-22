package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.dribble_goal_v031")
local s={frame=100,gs=0,ptr=0x0F00,remaining=5,px=554,py=262,bx=554,by=262,poss=0x0F00}
local st=P.new();local b,r
b,st,r=P.step(s,st)
for count=4,0,-1 do
 s.frame=s.frame+1;s.remaining=count
 b,st,r=P.step(s,st)
 if count==0 then assert(st.flags_frame==s.frame and st.phase=="goal")
 else assert(st.event:find("flag_collected",1,true)) end
end
s.frame=s.frame+1;s.px=1600;s.py=365;b,st,r=P.step(s,st)
assert(st.shot_frame==s.frame and st.event=="shot_started")
s.frame=s.frame+1;b,st,r=P.step(s,st);assert(st.event=="")
s.gs=6;s.frame=s.frame+1;b,st,r=P.step(s,st)
assert(st.event=="gameplay_exit_unverified" and st.exit_frame==s.frame)
s.frame=s.frame+1;b,st,r=P.step(s,st);assert(st.event=="")
print("test_dribble_goal_v031.lua OK")
