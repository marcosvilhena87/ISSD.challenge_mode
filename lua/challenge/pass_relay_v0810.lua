-- v0.8.10: permit visited teammates only as penalized two-leg relays.
local Feet=require("challenge.pass_feet_v0815")
local BallLine=require("challenge.pass_alignment_ball_v0817")
local M={VERSION="0.8.15",RELAY_PENALTY=100,MAX_CONSECUTIVE=2}
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
 local goals={}
 local early=0
 for id=2,9 do
  if not visited[id] then goals[id]=true;early=early+1 end
 end
 local stage="early"
 if early==0 then
  if not visited[11] then goals[11]=true;stage="penultimate_11"
  elseif not visited[10] then goals[10]=true;stage="last_10"
  else return nil,"all_visited" end
 end
 local best,score,details
 for id in pairs(goals) do
  if id~=holder and not (excluded and excluded[id]) and points[id] and Feet.check(sample,holder,id) and BallLine.check(sample,holder,id) then
   local direct=leg(points[holder],points[id])
   -- Strongly discourage long, hard-to-control direct passes.
   local cost=direct+math.max(0,direct-180)*2
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
    if second and first<=200 and second<=200 then
     local total=first+second+M.RELAY_PENALTY
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
