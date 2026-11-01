-- v0.8.20 ordered handoffs and bounded approach.
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.20",ROUTE={6,2,3,4,5,8,9,7,10,11},MAX_APPROACH=90}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.next(index,holder)
 index=index or 1
 if index>=#M.ROUTE then return nil,"complete" end
 if holder~=M.ROUTE[index] then return nil,"unexpected_holder" end
 return M.ROUTE[index+1],"ordered"
end
function M.step(sample,holder,target)
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b or not sample.ball then return {}, "missing_geometry" end
 local bx,by=sample.ball.x-a.x,sample.ball.y-a.y
 if bx*bx+by*by>18*18 then return {},"ball_not_at_feet" end
 local ok,why,metrics=Feet.check(sample,holder,target)
 if ok then return {},"target_in_range" end
 if why~="too_far" and why~="diagonal_risk" then return {},why end
 local dx,dy=b.x-a.x,b.y-a.y
 -- One cardinal frame at a time. The caller requires a neutral frame between pulses.
 local key
 if math.abs(dx)>=math.abs(dy) then key=dx>=0 and "Right" or "Left"
 else key=dy>=0 and "Down" or "Up" end
 return {[key]=true},"approach_step",metrics
end
return M
