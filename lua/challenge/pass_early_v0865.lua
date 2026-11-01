-- v0.8.65: bounded early-pass trial for player 7 -> 10.
-- No claim that a long pass will reach the intended receiver.
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.65",MIN_APPROACH=24,MAX_DISTANCE=420,MAX_LATERAL=160}
function M.evaluate(sample,holder,target,frames,already)
 if already or holder~=7 or target~=10 or frames<M.MIN_APPROACH then return false,"not_eligible" end
 local m=Feet.measure(sample,7,10)
 if not m then return false,"missing_geometry" end
 if m.distance> M.MAX_DISTANCE or m.distance<Feet.MIN_PASS_DISTANCE then return false,"out_of_band",m end
 if m.lateral>M.MAX_LATERAL then return false,"lateral_risk",m end
 if not sample or not sample.ball then return false,"missing_ball",m end
 local a
 for _,p in ipairs(sample.players or {}) do if p.id==7 then a=p end end
 if not a then return false,"missing_holder",m end
 local d2=(sample.ball.x-a.x)^2+(sample.ball.y-a.y)^2
 if d2>18*18 then return false,"ball_not_at_feet",m end
 return true,"bounded_trial",m
end
return M
