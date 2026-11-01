-- v0.8.17: verify A-ball-B near-collinearity; no claim about engine kick physics.
local M={VERSION="0.8.17",MAX_BALL_OFFSET=18,MAX_LINE_ERROR=12,MAX_BEHIND=5}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.check(sample,from,to)
 local a,b=find(sample,from),find(sample,to)
 local ball=sample and sample.ball
 if not a or not b or not ball then return false,"missing_geometry" end
 local vx,vy=b.x-a.x,b.y-a.y
 local length=math.sqrt(vx*vx+vy*vy)
 if length<12 then return false,"too_close" end
 local ox,oy=ball.x-a.x,ball.y-a.y
 local offset=math.sqrt(ox*ox+oy*oy)
 local along=(ox*vx+oy*vy)/length
 local lateral=math.abs(ox*vy-oy*vx)/length
 local metrics={ball_offset=offset,along=along,lateral=lateral,range=length}
 if offset>M.MAX_BALL_OFFSET then return false,"ball_not_at_feet",metrics end
 if along< -M.MAX_BEHIND then return false,"ball_behind_carrier",metrics end
 if lateral>M.MAX_LINE_ERROR then return false,"ball_off_pass_axis",metrics end
 return true,"ball_aligned",metrics
end
return M
