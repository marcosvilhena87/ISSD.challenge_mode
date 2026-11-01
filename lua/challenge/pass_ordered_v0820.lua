-- v0.8.22: preserve preferred order but recover from actual receiver.
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.22",ROUTE={6,2,3,4,5,8,9,7,10,11},MAX_APPROACH=90}
local function find(sample,id)
 for _,p in ipairs(sample and sample.players or {}) do if p.id==id then return p end end
end
function M.next(_,holder,visited)
 visited=visited or {}
 if not holder or holder<2 or holder>11 then return nil,"invalid_holder" end
 for _,id in ipairs(M.ROUTE) do
  if id~=holder and not visited[id] then return id,"ordered_remaining" end
 end
 return nil,"all_visited"
end
function M.step(sample,holder,target)
 local a,b=find(sample,holder),find(sample,target)
 if not a or not b or not sample.ball then return {},"missing_geometry" end
 local bx,by=sample.ball.x-a.x,sample.ball.y-a.y
 if bx*bx+by*by>18*18 then return {},"ball_not_at_feet" end
 local safe,why,metrics=Feet.check(sample,holder,target)
 if safe then return {},"target_in_range" end
 if why~="too_far" and why~="diagonal_risk" then return {},why end
 local dx,dy=b.x-a.x,b.y-a.y
 local key
 if math.abs(dx)>=math.abs(dy) then key=dx>=0 and "Right" or "Left"
 else key=dy>=0 and "Down" or "Up" end
 return {[key]=true},"approach_step",metrics
end
return M
