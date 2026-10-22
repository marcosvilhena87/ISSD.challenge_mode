-- DRIBBLE v0.3.1: reuse v0.3 control; add event and finish deduplication.
local Base=require("challenge.dribble_goal_v03")
local M={}
function M.new()
 return {base=Base.new(),seen={},event="",phase="flags",flags_frame=nil,shot_frame=nil,exit_frame=nil,goal_evidence="unverified"}
end
function M.step(s,st)
 st=st or M.new();st.event=""
 local buttons,base,reason=Base.step(s,st.base);st.base=base;st.phase=base.phase
 for _,event in ipairs(base.events or {}) do
  if not st.seen[event] then
   st.seen[event]=true
   st.event=(st.event=="" and event or st.event.."|"..event)
   if event=="five_flags_collected" then st.flags_frame=s.frame end
   if event=="shot_started" then st.shot_frame=s.frame end
   if event=="gameplay_exit_unverified" then st.exit_frame=s.frame end
  end
 end
 return buttons,st,reason
end
return M
