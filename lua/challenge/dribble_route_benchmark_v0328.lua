-- DRIBBLE v0.3.2.8: passive deterministic-route benchmark.
-- Baseline from v0.3.2.7 observed session, not a guaranteed game invariant.
local M={}
M.BASELINE={176,244,204,172,192}
function M.new(arm)
 return {arm=arm,previous_frame=nil,observations={},complete=false,discontinuities=0}
end
function M.flag(st,number,s,active)
 if number~= #st.observations+1 or number<1 or number>5 then
  st.discontinuities=st.discontinuities+1;return nil
 end
 local previous=st.previous_frame or (active and active.active_frame) or st.arm
 local elapsed=s.frame-previous
 local baseline=M.BASELINE[number]
 local row={number=number,frame=s.frame,segment_frames=elapsed,
  baseline_frames=baseline,delta_frames=elapsed-baseline,
  start_basis=(number==1 and (active and active.active_frame and "active_candidate" or "arm") or "previous_flag"),
  px=s.px,py=s.py,bx=s.bx,by=s.by,
  poss=s.poss,time=s.time,remaining=s.remaining,
  active_frame=active and active.active_frame or nil,
  valid_start=active and active.valid_start or false}
 st.observations[#st.observations+1]=row;st.previous_frame=s.frame
 st.complete=(#st.observations==5)
 return row
end
function M.result(st)
 local comparable=st.complete and st.discontinuities==0
 local total=0
 for _,v in ipairs(st.observations) do
  if v.number==1 and (v.start_basis~="active_candidate" or not v.valid_start) then
   comparable=false
  end
  total=total+v.delta_frames
 end
 return {comparable=comparable,observed=#st.observations,
  delta_total=comparable and total or nil,
  status=comparable and (total==0 and "reference_time_match" or "timing_deviation") or "incomplete_or_not_comparable"}
end
return M
