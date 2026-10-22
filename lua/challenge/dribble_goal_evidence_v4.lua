-- DRIBBLE Goal Evidence v4: contextual, passive, does not validate the score.
local M={}
function M.new(s)
 return {arm=s.frame,base=s.goal,initial_remaining=s.remaining,
   valid_start=s.gs==0 and s.ptr==0x0F00 and s.remaining==5,
   last_remaining=s.remaining,flags_frame=nil,shot_frame=nil,shot_marker=nil,
   increment_frame=nil,increment_gs=nil,increment_remaining=nil,
   delta=nil,increment_count=0,reset_count=0,visual=false,negative=false,
   byte_mismatch=0,last_goal=s.goal,last_gs=s.gs}
end
function M.step(st,s)
 local ev=nil
 if type(s.goal)~="number" or type(s.remaining)~="number" then return "invalid_read" end
 if type(s.lo)=="number" and type(s.hi)=="number" and s.goal~=s.lo+256*s.hi then
  st.byte_mismatch=st.byte_mismatch+1;ev="byte_mismatch"
 end
 if st.last_remaining==1 and s.remaining==0 and s.gs==0 and not st.flags_frame then
  st.flags_frame=s.frame;ev="fifth_flag_observed"
 end
 if st.last_goal and s.goal~=st.last_goal then
  local d=s.goal-st.last_goal
  if d>0 then
   st.increment_count=st.increment_count+1
   if not st.increment_frame then
    st.increment_frame=s.frame;st.increment_gs=s.gs
    st.increment_remaining=s.remaining;st.delta=d
   end
   ev="goal_counter_increment"
  else st.reset_count=st.reset_count+1;ev="goal_counter_reset_or_decrease" end
 end
 st.last_remaining=s.remaining;st.last_goal=s.goal;st.last_gs=s.gs
 return ev
end
function M.marker(st,event,frame)
 if event=="BEFORE_SHOT" then st.shot_marker=frame
 elseif event=="SHOT_STARTED" then st.shot_frame=frame
 elseif event=="GOAL_VISUAL_CONFIRMED" then st.visual=true
 elseif event=="SHOT_MISSED" or event=="NO_GOAL_EXIT" then st.negative=true end
end
function M.classify(st)
 if st.negative and st.increment_count>0 then return "conflicting_negative_evidence" end
 if st.negative and st.increment_count==0 then return "negative_control_no_increment" end
 if st.visual and st.increment_count==0 then return "visual_goal_without_increment" end
 if st.increment_count==0 then return "no_increment_unverified" end
 if not st.valid_start or not st.flags_frame or st.increment_remaining~=0
   or st.increment_gs~=5 or st.delta~=1
   or st.increment_frame<=st.flags_frame
   or not (st.shot_frame or st.shot_marker)
   or (st.shot_frame and st.shot_frame>st.increment_frame)
   or (st.shot_marker and st.shot_marker>st.increment_frame)
   or st.byte_mismatch>0 or st.reset_count>0 or st.increment_count~=1 then
  return "increment_outside_validated_dribble_context"
 end
 if st.visual then return "contextual_goal_correlated_visual" end
 return "contextual_goal_candidate"
end
return M
