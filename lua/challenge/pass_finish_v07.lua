-- PASS v0.8.13: one opt-in X shot after 10 spatial visitors + matching bonus countdown.
-- Goalkeeper y is an unverified proxy for the center of goal, NOT a calibrated goal coordinate.
local M={VERSION="0.8.60",MAX_GOALKEEPER_X=135,MAX_APPROACH_FRAMES=120}
function M.new()
 return {enabled=false,phase="waiting",completion_frame=nil,shot_frame=nil,shots=0,
  aim=nil,aim_reason=nil,approach_frames=0,approach_x_start=nil,approach_best=nil}
end
function M.geometry(sample)
 if not sample or not sample.ball or not sample.goalkeeper then return nil,"no_goalkeeper_sample" end
 local b,k=sample.ball,sample.goalkeeper
 for _,v in ipairs({b.x,b.y,k.x,k.y}) do
  if type(v)~="number" or v~=v or math.abs(v)>4096 then return nil,"invalid_coordinate_domain" end
 end
 local dx,dy=k.x-b.x,k.y-b.y
 if math.abs(dx)>1024 or math.abs(dy)>512 then return nil,"goalkeeper_coordinate_mismatch" end
 return {dx=dx,dy=dy,gap=math.abs(dx)}
end
function M.aim(sample)
 if not sample or not sample.ball or not sample.goalkeeper then return nil,"no_goalkeeper_sample" end
 local ball,keeper=sample.ball,sample.goalkeeper
 if type(ball.x)~="number" or type(ball.y)~="number" or
    type(keeper.x)~="number" or type(keeper.y)~="number" then
  return nil,"invalid_goalkeeper_coordinates"
 end
 local g,why=M.geometry(sample)
 if not g then return nil,why end
 local dx,dy=g.dx,g.dy
 if math.abs(dx)<16 then return nil,"ambiguous_goal_side" end
 local buttons={}
 buttons[dx>0 and "Right" or "Left"]=true
 -- Keeper's vertical position is only a rough heuristic for goal center.
 if dy>24 then buttons.Down=true elseif dy< -24 then buttons.Up=true end
 return buttons,"goalkeeper_y_proxy"
end
function M.step(t,frame,completion_frame,bonus_first_decrement,sample,stable_holder)
 if not t.enabled then return {},"disabled" end
 if t.phase=="done" then return {},"done" end
 if not completion_frame then return {},"await_ten_spatial_candidates" end
 if not bonus_first_decrement or bonus_first_decrement<completion_frame then
  return {},"await_bonus_countdown_correspondence"
 end
 if frame-bonus_first_decrement>180 or frame-completion_frame>240 then
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
    t.enabled=false;return {},"shot_blocked_too_far"
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
   move[dx>0 and "Right" or "Left"]=true
   -- Correct severe Y mismatch gradually; no pass or X during approach.
   if math.abs(dy)>90 then move[dy>0 and "Down" or "Up"]=true end
   return move,"finish_goal_approach"
  end
  t.aim=aim;t.aim_reason=why;t.completion_frame=completion_frame
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
