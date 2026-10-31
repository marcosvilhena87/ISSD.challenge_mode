-- PASS LV.1 v0.7.1: exactly one diagnostic B pass per ARM.
-- Direction + B are held together; all observations remain hypotheses.
local M={}
function M.new()
 return {enabled=false,button="B",phase="idle",start_frame=nil,tries=0,
 target=nil,origin=nil,pass_frame=nil,ball_before=nil,ball_max_displacement=0,
 hold_frames=3,wait_frames=90,last_attempt=nil}
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
   t.ball_max_displacement=math.max(t.ball_max_displacement,distance(sample.ball,t.ball_before))
  end
  if holder and holder~=t.origin then
   t.enabled=false;t.phase="done"
   return empty,"transfer_candidate_observed"
  end
  if frame-(t.pass_frame or frame)>=t.wait_frames then
   t.enabled=false;t.phase="done"
   return empty,t.ball_max_displacement>=8 and "ball_moved_without_transfer" or "no_ball_motion_detected"
  end
  return empty,"await_ball_motion"
 end
 if t.phase=="hold" then
  local dest=find(sample and sample.players,t.target)
  local origin=find(sample and sample.players,t.origin)
  if not dest or not origin then t.enabled=false;return empty,"coordinates_lost" end
  local dx,dy=dest.x-origin.x,dest.y-origin.y
  local buttons={B=true}
  if dx>12 then buttons.Right=true elseif dx< -12 then buttons.Left=true end
  if dy>12 then buttons.Down=true elseif dy< -12 then buttons.Up=true end
  t.hold_count=t.hold_count+1
  if t.hold_count>=t.hold_frames then
   t.phase="wait";t.pass_frame=frame;t.tries=1
   t.ball_before={x=sample.ball.x,y=sample.ball.y}
   t.last_attempt={frame=frame,from=t.origin,to=t.target,button="B",hold_frames=t.hold_frames}
   return buttons,"pass_pulse"
  end
  return buttons,"direction_and_B_hold"
 end
 if t.phase=="idle" then
  if not sample or not sample.ball or not holder then return empty,"no_stable_holder" end
  local target=plan and plan.sequence and plan.sequence[1]
  if not target or target==holder or not find(sample.players,target) then
   return empty,"no_valid_target"
  end
  t.origin=holder;t.target=target;t.phase="hold";t.hold_count=0
  return empty,"target_selected"
 end
 return empty,"done"
end
return M
