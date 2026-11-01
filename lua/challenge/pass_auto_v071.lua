-- PASS LV.1 v0.7.1: exactly one diagnostic B pass per ARM.
-- Direction + B are held together; all observations remain hypotheses.
local M={}
function M.new()
 return {enabled=false,button="B",phase="idle",start_frame=nil,tries=0,
 target=nil,origin=nil,pass_frame=nil,ball_before=nil,ball_max_displacement=0,
 trigger_delay=0,prewait_until=nil,hold_frames=3,wait_frames=90,extra_wait_frames=90,extended=false,first_motion_frame=nil,flight_samples={},last_attempt=nil,direction="AUTO",align_frames=2}
end
local function find(players,id)
 for _,p in ipairs(players or {}) do if p.id==id then return p end end
end
local function distance(a,b)
 local dx,dy=a.x-b.x,a.y-b.y
 return math.sqrt(dx*dx+dy*dy)
end
function M.step(t,frame,sample,holder,visited,plan,bonus_finished)
 local empty={}
 if not t.enabled then return empty,"disabled" end
 if t.button~="B" then t.enabled=false;return empty,"invalid_pass_button" end
 if bonus_finished then t.enabled=false;return empty,"completion_candidate_stop" end
 if t.start_frame and frame-t.start_frame>3600 then t.enabled=false;return empty,"timeout" end
 if t.phase=="wait" then
  if sample and sample.ball and t.ball_before then
   local displacement=distance(sample.ball,t.ball_before)
   t.ball_max_displacement=math.max(t.ball_max_displacement,displacement)
   if not t.first_motion_frame and displacement>=8 then t.first_motion_frame=frame end
   if frame%10==0 then
    local target=find(sample.players,t.target)
    local target_distance=target and distance(sample.ball,target) or nil
    t.flight_samples[#t.flight_samples+1]={frame=frame,x=sample.ball.x,y=sample.ball.y,
      displacement=displacement,target_distance=target_distance}
   end
  end
  if holder and holder~=t.origin then
   t.enabled=false;t.phase="done"
   return empty,"transfer_candidate_observed"
  end
  if frame-(t.pass_frame or frame)>=t.wait_frames then
   if not t.extended and t.ball_max_displacement>=8 then
    t.extended=true;t.wait_frames=t.wait_frames+t.extra_wait_frames
    return empty,"flight_wait_extended"
   end
   t.enabled=false;t.phase="done"
   return empty,t.ball_max_displacement>=8 and "ball_moved_without_transfer" or "no_ball_motion_detected"
  end
  return empty,"await_ball_motion"
 end
 if t.phase=="prewait" then
  if frame<(t.prewait_until or frame) then return empty,"trigger_pre_wait" end
  t.phase=t.next_phase or "hold"
  -- Deliberately no buttons on the transition frame.
  return empty,"trigger_pre_wait_complete"
 end
 if t.phase=="align" then
  local dest=find(sample and sample.players,t.target)
  local origin=find(sample and sample.players,t.origin)
  if not dest or not origin then t.enabled=false;return empty,"coordinates_lost" end
  local dx,dy=dest.x-origin.x,dest.y-origin.y
  local buttons={}
  if dx>12 then buttons.Right=true elseif dx< -12 then buttons.Left=true end
  if dy>12 then buttons.Down=true elseif dy< -12 then buttons.Up=true end
  t.align_count=(t.align_count or 0)+1
  if t.align_count>=t.align_frames then t.phase="hold" end
  return buttons,"alignment_correction"
 end
 if t.phase=="hold" then
  local dest=find(sample and sample.players,t.target)
  local origin=find(sample and sample.players,t.origin)
  if not dest or not origin then t.enabled=false;return empty,"coordinates_lost" end
  local dx,dy=dest.x-origin.x,dest.y-origin.y
  local buttons={}
  local direction=t.direction or "AUTO"
  if direction=="AUTO" then
   if dx>12 then buttons.Right=true elseif dx< -12 then buttons.Left=true end
   if dy>12 then buttons.Down=true elseif dy< -12 then buttons.Up=true end
   if not (buttons.Left or buttons.Right or buttons.Up or buttons.Down) then
    if math.abs(dx)>=math.abs(dy) then buttons[dx>=0 and "Right" or "Left"]=true
    else buttons[dy>=0 and "Down" or "Up"]=true end
   end
  elseif direction~="NEUTRAL" then
   for key in direction:gmatch("[^_]+") do buttons[key]=true end
  end
  -- B is valid only when a control-pad direction is pressed in the SAME frame.
  if not (buttons.Left or buttons.Right or buttons.Up or buttons.Down) then
   t.enabled=false;t.phase="done";return {},"no_direction_for_pass"
  end
  buttons.B=true
  t.hold_count=t.hold_count+1
  if t.hold_count>=t.hold_frames then
   t.phase="wait";t.pass_frame=frame;t.tries=1
   -- Preserve the pre-input position from target selection.
   t.last_attempt={frame=frame,from=t.origin,to=t.target,button="B",hold_frames=t.hold_frames,direction=t.direction,alignment_frames=t.align_count or 0}
   return buttons,"pass_pulse"
  end
  return buttons,"direction_and_B_hold"
 end
 if t.phase=="idle" then
  if not sample or not sample.ball or not holder then return empty,"no_stable_holder" end
  local target=plan and (plan.target or (plan.sequence and plan.sequence[1]))
  if not target or target==holder or not find(sample.players,target) then
   t.enabled=false;return empty,"no_valid_target"
  end
  local origin=find(sample.players,holder)
  local dest=find(sample.players,target)
  local range=distance(origin,dest)
  t.wait_frames=range<=150 and 90 or (range<=300 and 150 or 210)
  t.extended=false;t.first_motion_frame=nil;t.flight_samples={}
  t.origin=holder;t.target=target
  t.next_phase=(plan and plan.aligned==false) and "align" or "hold"
  if (t.trigger_delay or 0)>0 then
   t.phase="prewait";t.prewait_until=frame+t.trigger_delay
  else t.phase=t.next_phase end
  t.hold_count=0;t.align_count=0
  t.ball_before={x=sample.ball.x,y=sample.ball.y}
  return empty,"target_selected"
 end
 return empty,"done"
end
return M
