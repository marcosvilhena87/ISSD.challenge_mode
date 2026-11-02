-- PASS v0.8.13: one opt-in X shot after 10 spatial visitors + matching bonus countdown.
-- Goal position is derived from stadium geometry; endpoint/attack side require calibration.
local M={VERSION="0.9.7",MAX_GOALKEEPER_X=135,MAX_APPROACH_FRAMES=210}
function M.new()
 return {enabled=false,phase="waiting",completion_frame=nil,shot_frame=nil,shots=0,
  aim=nil,aim_reason=nil,approach_frames=0,approach_x_start=nil,approach_best=nil,
  approach_last_gap=nil,approach_stall_frames=0,approach_mode=0,
  approach_recoveries=0,approach_last_event=nil,approach_last_dy=nil}
end
function M.geometry(sample)
 if not sample or not sample.ball or not sample.goal_reference then return nil,"no_stadium_goal_reference" end
 local ball,goal=sample.ball,sample.goal_reference
 for _,v in ipairs({ball.x,ball.y,goal.x,goal.y}) do
  if type(v)~="number" or v~=v or math.abs(v)>65535 then return nil,"invalid_coordinate_domain" end
 end
 local dx,dy=goal.x-ball.x,goal.y-ball.y
 -- No goalkeeper slot and no unbounded chase using an uncalibrated scale.
 if math.abs(dx)>1024 or math.abs(dy)>512 then return nil,"stadium_goal_coordinate_mismatch" end
 if dx<=0 then return nil,"stadium_attack_side_unverified" end
 return {dx=dx,dy=dy,gap=math.abs(dx)}
end
function M.aim(sample)
 local g,why=M.geometry(sample)
 if not g then return nil,why end
 if math.abs(g.dx)<16 then return nil,"ambiguous_goal_side" end
 local buttons={Right=true}
 if g.dy>24 then buttons.Down=true elseif g.dy< -24 then buttons.Up=true end
 return buttons,"stadium_goal_candidate"
end
function M.step(t,frame,completion_frame,bonus_first_decrement,sample,stable_holder)
 if not t.enabled then return {},"disabled" end
 if t.phase=="done" then return {},"done" end
 if not completion_frame then return {},"await_ten_spatial_candidates" end
 if not bonus_first_decrement or bonus_first_decrement<completion_frame then
  return {},"await_bonus_countdown_correspondence"
 end
 if frame-bonus_first_decrement>330 or frame-completion_frame>390 then
  t.enabled=false;return {},"finish_window_expired"
 end
 if t.phase=="waiting" or t.phase=="approach_goal" then
  if not stable_holder then return {},"await_stable_holder" end
  local aim,why=M.aim(sample)
  if not aim then t.enabled=false;return {},why end
  local geometry,geometry_reason=M.geometry(sample)
  if not geometry then t.enabled=false;return {},geometry_reason end
  local dx,dy,gap=geometry.dx,geometry.dy,geometry.gap
  t.approach_x_start=t.approach_x_start or gap
  t.approach_best=math.min(t.approach_best or gap,gap)
  if gap>M.MAX_GOALKEEPER_X then
   if (t.approach_frames or 0)>=M.MAX_APPROACH_FRAMES then
    t.enabled=false
    t.aim_reason="approach_limit|gap="..tostring(gap).."|best="..tostring(t.approach_best)..
      "|frames="..tostring(t.approach_frames)
    return {},"shot_blocked_too_far"
   end
   -- Measure true progress; if movement stalls, alternate diagonal/cardinal
   -- alignment before giving up. Never shoot when still out of range.
   if t.approach_last_gap and gap<t.approach_last_gap-0.5 then
    t.approach_stall_frames=0
   else
    t.approach_stall_frames=(t.approach_stall_frames or 0)+1
   end
   t.approach_last_gap=gap
   if t.approach_stall_frames>=15 then
    t.approach_stall_frames=0
    t.approach_mode=(t.approach_mode+1)%3
    t.approach_recoveries=t.approach_recoveries+1
    t.approach_last_event="finish_approach_recovery"
   end
   if t.approach_recoveries>=9 then
    t.enabled=false
    t.aim_reason="no_progress|gap="..tostring(gap)..
      "|recoveries="..tostring(t.approach_recoveries)
    return {},"shot_blocked_no_progress"
   end
   -- Only move when the ball is demonstrably at the current holder's feet.
   local holder_found=false
   for _,p in ipairs(sample.players or {}) do
    if p.id==stable_holder and p.x and p.y then
     local px,py=sample.ball.x-p.x,sample.ball.y-p.y
     holder_found=px*px+py*py<=18*18
     break
    end
   end
   if not holder_found then return {},"await_ball_at_holder_feet" end
   t.phase="approach_goal"
   t.approach_frames=t.approach_frames+1
   local move={}
   if t.approach_mode~=2 then move[dx>0 and "Right" or "Left"]=true end
   if math.abs(dy)>40 and t.approach_mode~=1 then
    move[dy>0 and "Down" or "Up"]=true
   end
   if not next(move) then move.Right=true end
   return move,"finish_goal_approach"
  end
  t.aim=aim;t.aim_reason=why;t.completion_frame=completion_frame
  t.approach_last_event="finish_shot_ready"
  t.phase="release";return {},"completion_and_bonus_observed"
 elseif t.phase=="release" then
  t.phase="shoot";return {},"release"
 elseif t.phase=="shoot" then
  t.phase="done";t.shot_frame=frame;t.shots=t.shots+1
  local shot={X=true}
  for k,v in pairs(t.aim or {}) do shot[k]=v end
  return shot,"shoot_pulse"
 end
 return {},"done"
end
return M
