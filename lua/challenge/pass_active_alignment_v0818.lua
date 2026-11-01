-- v0.8.18: bounded observational alignment assistance.
-- Never claims to know sprite facing or game kick physics.
local BallLine=require("challenge.pass_alignment_ball_v0817")
local M={VERSION="0.8.18",MAX_FRAMES=12,MAX_STEP_FRAMES=2}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.direction(sample,from,to,reason)
 local a,b=find(sample,from),find(sample,to)
 if not a or not b or not sample or not sample.ball then return nil,"missing_geometry" end
 if reason=="ball_not_at_feet" then return nil,"ball_not_at_feet" end
 local vx,vy=b.x-a.x,b.y-a.y
 local length=math.sqrt(vx*vx+vy*vy)
 if length<12 then return nil,"too_close" end
 local ox,oy=sample.ball.x-a.x,sample.ball.y-a.y
 local cross=ox*vy-oy*vx
 local along=(ox*vx+oy*vy)/length
 if reason=="ball_behind_carrier" or along< -BallLine.MAX_BEHIND then
  -- Moving toward the receiver may place the ball farther behind the carrier:
  -- use only facing direction for one short attempt.
  if math.abs(vx)>=math.abs(vy) then return vx>=0 and "Right" or "Left","face_forward" end
  return vy>=0 and "Down" or "Up","face_forward"
 end
 -- Move A sideways, aiming to reduce the signed lateral error of ball to AB.
 -- Physical response is not calibrated; abort on regression from observed metrics.
 if math.abs(vx)>=math.abs(vy) then
  return cross>0 and "Down" or "Up","lateral_correction"
 end
 return cross>0 and "Left" or "Right","lateral_correction"
end
function M.step(state,frame,sample,from,to)
 local ok,reason,metrics=BallLine.check(sample,from,to)
 if ok then return {},"alignment_acquired",metrics end
 if reason=="missing_geometry" or reason=="too_close" or reason=="ball_not_at_feet" then
  return {},"alignment_unrecoverable_"..reason,metrics
 end
 if (state.steps or 0)>=M.MAX_STEP_FRAMES then return {},"alignment_timeout",metrics end
 if frame-(state.started or frame)>=M.MAX_FRAMES then return {},"alignment_timeout",metrics end
 if state.previous_lateral and metrics and metrics.lateral>state.previous_lateral+3 then
  return {},"alignment_regressed",metrics
 end
 local dir,why=M.direction(sample,from,to,reason)
 if not dir then return {},"alignment_unrecoverable_"..tostring(why),metrics end
 state.previous_lateral=metrics and metrics.lateral
 state.steps=(state.steps or 0)+1
 return {[dir]=true},"alignment_adjust_"..why,metrics
end
return M
