-- PASS LV.1 v0.7: conservative automatic finishing after spatial completion.
-- B for passing, X for shooting (operator-confirmed). Goal direction unverified.
local M={}
function M.new()
 return {enabled=false,phase="waiting",completion_frame=nil,shot_frame=nil,shots=0}
end
function M.step(state,frame,completion_frame,bonus_first_decrement,goal_direction)
 if not state.enabled then return {},"disabled" end
 if state.phase=="done" then return {},"done" end
 if not completion_frame then return {},"await_ten_spatial_candidates" end
 if not bonus_first_decrement or bonus_first_decrement<completion_frame then
  return {},"await_bonus_countdown_correspondence"
 end
 if frame-bonus_first_decrement>180 or frame-completion_frame>240 then
  state.enabled=false;return {},"finish_window_expired"
 end
 if state.phase=="waiting" then
  state.completion_frame=completion_frame
  -- No goal coordinate mapping is validated for PASS. Never guess direction.
  state.phase="release"
  return {},"completion_and_bonus_observed"
 elseif state.phase=="release" then
  state.phase="shoot";return {},"release"
 elseif state.phase=="shoot" then
  state.phase="done";state.shot_frame=frame;state.shots=state.shots+1
  return {X=true},"shoot_pulse"
 end
 return {},"done"
end
return M
