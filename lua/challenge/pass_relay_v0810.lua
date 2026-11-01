-- v0.8.10: permit visited teammates only as penalized two-leg relays.
local Feet=require("challenge.pass_feet_v0815")
local BallLine=require("challenge.pass_alignment_ball_v0817")
local M={VERSION="0.8.20",RELAY_PENALTY=100,MAX_CONSECUTIVE=2}
local function leg(a,b)
 local dx,dy=math.abs(a.x-b.x),math.abs(a.y-b.y)
 return math.sqrt(dx*dx+dy*dy)+0.25*math.max(0,math.min(dx,dy)-12)
end
function M.choose(sample,holder,visited,previous,consecutive,excluded)
 local points={}
 for _,p in ipairs(sample and sample.players or {}) do
  if p.id and type(p.x)=="number" and type(p.y)=="number" then points[p.id]=p end
 end
 if not points[holder] then return nil,"missing_holder" end
 local order={6,2,3,4,5,8,9,7,10,11}
 local goals={}
 local next_goal=nil
 for _,id in ipairs(order) do
  if not visited[id] then next_goal=id;break end
 end
 if not next_goal then return nil,"all_visited" end
 -- The next missing player is preferred; later players are fallback only if needed.
 local ranks={}
 for rank,id in ipairs(order) do
  ranks[id]=rank
  if not visited[id] then goals[id]=true end
 end
 local stage="ordered_next_"..tostring(next_goal)
 local best,score,details
 for id in pairs(goals) do
  if id~=holder and not (excluded and excluded[id]) and points[id] and Feet.check(sample,holder,id) then
   local direct=leg(points[holder],points[id])
   -- Strongly discourage long, hard-to-control direct passes.
   local priority_penalty=(id==next_goal) and 0 or 10000
   local cost=direct+math.max(0,direct-180)*2+priority_penalty
   if not best or cost<score then
    best=id;score=cost;details={mode="new",immediate=direct,onward=0,total=cost}
   end
  end
 end
 if (consecutive or 0)<M.MAX_CONSECUTIVE then
  for id=2,11 do
   if visited[id] and id~=holder and id~=previous and not (excluded and excluded[id]) and points[id]
     and not (id==10 or id==11) and Feet.check(sample,holder,id) then
    local first=leg(points[holder],points[id])
    local second
    for goal in pairs(goals) do
     if points[goal] and goal~=id and Feet.check(sample,id,goal) then
      local d=leg(points[id],points[goal])
      if not second or d<second then second=d end
     end
    end
    if second and first<=Feet.MAX_RANGE and second<=Feet.MAX_RANGE then
     local total=first+second+M.RELAY_PENALTY
     if next_goal and points[next_goal] and Feet.check(sample,id,next_goal) then
      total=total-80
     end
     if not best or total<score then
      best=id;score=total
      details={mode="relay",immediate=first,onward=second,
       penalty=M.RELAY_PENALTY,total=total}
     end
    end
   end
  end
 end
 return best,best and "selected" or "no_reachable_target",details,stage
end
return M
