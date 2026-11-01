-- PASS v0.8.9: bounded coordinate lookahead for remaining outfield players.
-- Recompute after every observed transfer; 11 and 10 remain reserved.
local M={VERSION="0.8.9"}
local function dist(a,b)
 local dx,dy=a.x-b.x,a.y-b.y
 return math.sqrt(dx*dx+dy*dy)
end
local function leg(a,b)
 local dx,dy=math.abs(a.x-b.x),math.abs(a.y-b.y)
 return math.sqrt(dx*dx+dy*dy)+0.25*math.max(0,math.min(dx,dy)-12)
end
local function locate(points,id)
 return points[id]
end
local function future_cost(points,start,visited)
 local remaining={}
 for id=2,9 do if not visited[id] and points[id] then remaining[id]=true end end
 local at=start
 local cost=0
 for _=1,8 do
  local best,score
  for id in pairs(remaining) do
   local value=leg(points[at],points[id])
   if not best or value<score or (value==score and id<best) then
    best=id;score=value
   end
  end
  if not best then break end
  cost=cost+score;remaining[best]=nil;at=best
 end
 if points[11] and not visited[11] and at~=11 then
  cost=cost+leg(points[at],points[11]);at=11
 end
 if points[10] and not visited[10] and at~=10 then
  cost=cost+leg(points[at],points[10])
 end
 return cost
end
function M.choose(sample,holder,visited,report,stage)
 local points={}
 for _,p in ipairs(sample and sample.players or {}) do
  if type(p.id)=="number" and type(p.x)=="number" and type(p.y)=="number" then
   points[p.id]=p
  end
 end
 if not points[holder] or not report or not report.candidates then return nil end
 local best,best_cost
 local evaluated={}
 for _,candidate in ipairs(report.candidates) do
  local id=candidate.id
  if points[id] and not (visited and visited[id]) then
   local next_visited={}
   for k,v in pairs(visited or {}) do next_visited[k]=v end
   next_visited[id]=true
   local onward=future_cost(points,id,next_visited)
   local score=candidate.cost+onward
   evaluated[#evaluated+1]={id=id,immediate=candidate.cost,onward=onward,total=score}
   if not best or score<best_cost-0.000001 or
     (math.abs(score-best_cost)<=0.000001 and
      (candidate.cost<best.cost or (candidate.cost==best.cost and id<best.id))) then
    best=candidate;best_cost=score
   end
  end
 end
 table.sort(evaluated,function(a,b) return a.total<b.total or
  (a.total==b.total and a.id<b.id) end)
 return best,best_cost,evaluated
end
return M
