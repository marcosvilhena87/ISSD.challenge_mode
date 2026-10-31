-- PASS v0.5.1: pure observer of bonus countdown and spatial completion correlation.
local M={}
function M.new()
 local t={previous=nil,first_decrement_frame=nil,completion_frame=nil,
  completion_count=nil,events={},last_bonus=nil}
 function t:step(frame,s,count,completion_frame)
  local p=self.previous
  self.previous=s
  if completion_frame and not self.completion_frame then
   self.completion_frame=completion_frame;self.completion_count=count
  end
  if not s or not p or type(s.bonus)~="number" or type(p.bonus)~="number" then return nil end
  local kind
  if s.bonus==0 and p.bonus>=2 then
   kind="bonus_abrupt_reset_candidate"
  elseif s.bonus<p.bonus then
   if not self.first_decrement_frame then
    self.first_decrement_frame=frame
    kind="first_bonus_decrement"
   else kind="bonus_decrement" end
  elseif s.bonus>p.bonus then kind="bonus_increase_or_initialization" end
  if not kind then return nil end
  local delta=self.completion_frame and frame-self.completion_frame or nil
  local evidence="timer_observation_only"
  if kind=="first_bonus_decrement" then
   if self.completion_frame and self.completion_frame<=frame then
    evidence="first_decrement_after_spatial_completion_candidate"
   else evidence="first_decrement_without_spatial_completion" end
  end
  local event={frame=frame,kind=kind,previous_bonus=p.bonus,bonus=s.bonus,
   time=s.time,bonus_frac=s.bonus_frac,time_frac=s.time_frac,spatial_count=count,
   completion_frame=self.completion_frame,delta_frames=delta,evidence=evidence}
  self.events[#self.events+1]=event
  return event
 end
 return t
end
return M
