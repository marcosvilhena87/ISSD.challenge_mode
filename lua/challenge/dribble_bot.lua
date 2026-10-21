-- DRIBBLE LV.1 autonomous pilot v0.1 (experimental).
-- Pure policy: no memory or input APIs here.
local M={}
M.MAX_FRAMES=1800
local function valid(v) return type(v)=="number" and v%1==0 end
function M.decide(s,state)
 state=state or {}
 if not (valid(s.frame) and valid(s.game_state) and valid(s.ptr) and valid(s.player_x) and valid(s.player_y) and valid(s.ball_x) and valid(s.ball_y)) then
  return {}, "invalid_read"
 end
 if state.started and s.frame-state.started>=M.MAX_FRAMES then return {},"time_budget" end
 if s.game_state~=0 or s.ptr~=0x0F00 then return {},"not_playing" end
 local buttons={}
 local dx=s.ball_x-s.player_x
 local dy=s.ball_y-s.player_y
 -- Move towards loose ball, else advance toward increasing field X.
 -- Orientation / scoring direction is NOT verified: this is a calibration baseline.
 local possess=(s.possession==0x0F00)
 if not possess and (math.abs(dx)>20 or math.abs(dy)>20) then
  if math.abs(dx)>12 then buttons[dx>0 and "Right" or "Left"]=true end
  if math.abs(dy)>12 then buttons[dy>0 and "Down" or "Up"]=true end
  return buttons,"seek_ball"
 end
 local goal=s.field_length
 if not valid(goal) or goal<=0 then return {},"unknown_field" end
 buttons.Right=true
 -- Keep player near ball's Y when carrying.
 if dy>24 then buttons.Down=true elseif dy< -24 then buttons.Up=true end
 return buttons,"advance_right"
end
return M
