-- v0.3.2.7 passive Active Start Detector. Does not issue input.
local M={MIN_MOVE=3}
local function delta(x,y,a,b) return math.abs(x-a)+math.abs(y-b) end
function M.new(s)
 return {arm_frame=s.frame,arm_gs=s.gs,arm_ptr=s.ptr,arm_remaining=s.remaining,
   arm_px=s.px,arm_py=s.py,arm_bx=s.bx,arm_by=s.by,
   previous=s,first_ball=nil,first_player=nil,first_time_bcd=nil,
   first_time_fraction=nil,active_frame=nil,active_evidence=nil,
   complete=false,final_reason=nil,valid_start=s.gs==0 and s.ptr==0x0F00 and s.remaining==5}
end
local function mark(q,frame,why)
 if not q.active_frame or frame<q.active_frame then
  q.active_frame=frame;q.active_evidence=why
 end
end
function M.observe(q,s)
 if q.complete then return nil end
 if type(s.frame)~="number" or type(s.px)~="number" or type(s.py)~="number" or
  type(s.bx)~="number" or type(s.by)~="number" then
  return nil
 end
 if not q.first_ball and delta(s.bx,s.by,q.arm_bx,q.arm_by)>=M.MIN_MOVE then
  q.first_ball=s.frame;mark(q,s.frame,"ball_movement")
 end
 if not q.first_player and delta(s.px,s.py,q.arm_px,q.arm_py)>=M.MIN_MOVE then
  q.first_player=s.frame;mark(q,s.frame,"player_movement")
 end
 if not q.first_time_bcd and type(s.time)=="number" and
  type(q.previous.time)=="number" and s.time~=q.previous.time then
  q.first_time_bcd=s.frame;mark(q,s.frame,"timer_second_change")
 end
 if not q.first_time_fraction and type(s.timefrac)=="number" and
  type(q.previous.timefrac)=="number" and s.timefrac~=q.previous.timefrac then
  q.first_time_fraction=s.frame;mark(q,s.frame,"timer_fraction_change")
 end
 q.previous=s
 if q.first_ball and q.first_player and (q.first_time_bcd or q.first_time_fraction) then
  return M.finish(q,s.frame,"all_signals_observed")
 end
 if s.gs~=0 or s.ptr~=0x0F00 then return M.finish(q,s.frame,"gameplay_exit") end
 if type(s.remaining)=="number" and s.remaining<q.arm_remaining then
  return M.finish(q,s.frame,"first_flag_observed")
 end
 return nil
end
function M.finish(q,frame,reason)
 if q.complete then return nil end
 q.complete=true;q.finish_frame=frame;q.final_reason=reason
 return q
end
return M
