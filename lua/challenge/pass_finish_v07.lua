-- PASS v0.8.13: one opt-in X shot after 10 spatial visitors + matching bonus countdown.
-- Goalkeeper y is an unverified proxy for the center of goal, NOT a calibrated goal coordinate.
local M={}
function M.new()
 return {enabled=false,phase="waiting",completion_frame=nil,shot_frame=nil,shots=0,
  aim=nil,aim_reason=nil}
end
function M.aim(sample)
 if not sample or not sample.ball or not sample.goalkeeper then return nil,"no_goalkeeper_sample" end
 local ball,keeper=sample.ball,sample.goalkeeper
 if type(ball.x)~="number" or type(ball.y)~="number" or
    type(keeper.x)~="number" or type(keeper.y)~="number" then
  return nil,"invalid_goalkeeper_coordinates"
 end
 local dx,dy=keeper.x-ball.x,keeper.y-ball.y
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
 if t.phase=="waiting" then
  if not stable_holder then return {},"await_stable_holder" end
  local aim,why=M.aim(sample)
  if not aim then t.enabled=false;return {},why end
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
