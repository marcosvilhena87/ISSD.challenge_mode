-- PASS v0.8.26: passive use of shared v4 counter evidence, no DRIBBLE context assumptions.
local Core=require("challenge.goal_evidence_v4")
local M={WINDOW=300}
function M.read(read8,read16,frame)
 local function safe(fn,addr)
  local ok,v=pcall(fn,addr,"WRAM")
  return ok and type(v)=="number" and v or nil
 end
 return {frame=frame,goal=safe(read16,0x0DA2),lo=safe(read8,0x0DA2),
  hi=safe(read8,0x0DA3),gs=safe(read16,0x00BA),ptr=safe(read16,0x1ACC),
  remaining=safe(read8,0x006B4)}
end
function M.new(sample)
 if not sample or type(sample.goal)~="number" then return nil end
 return {core=Core.new(sample),shot=nil,complete=nil,bonus=nil,baseline=sample.goal,
  last=sample.goal,observed=0,increment_after_shot=0,contextual=0,closed=false}
end
function M.step(st,s)
 if not st or st.closed or not s or type(s.goal)~="number" then return nil end
 local previous=st.last
 local event=Core.step(st.core,s)
 st.last=s.goal
 if st.shot and s.frame>st.shot then
  st.observed=st.observed+1
  if previous and s.goal==previous+1 then
   st.increment_after_shot=st.increment_after_shot+1
   if st.complete and st.bonus and st.complete<=st.shot and st.bonus<=st.shot then
    st.contextual=st.contextual+1
   end
  end
  if s.frame-st.shot>=M.WINDOW then st.closed=true end
 end
 return event
end
function M.classify(st)
 if not st or not st.shot then return "no_shot_unverified" end
 if st.core.byte_mismatch>0 or st.core.reset_count>0 then return "counter_conflict_unverified" end
 if st.contextual==1 and st.increment_after_shot==1 then return "pass_contextual_goal_candidate" end
 if st.increment_after_shot>0 then return "increment_not_validated_for_pass" end
 return st.closed and "no_increment_in_window" or "awaiting_post_shot_observation"
end
return M
