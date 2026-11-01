-- PASS v0.8.7: postpone 11 then 10 when possible; no guaranteed recipient.
local Route=require("challenge.pass_route_v089")
local M={VERSION="0.8.9"}
function M.allowed(visited,holder)
 local remaining_early=0
 for id=2,9 do
  if id~=holder and not (visited and visited[id]) then remaining_early=remaining_early+1 end
 end
 if remaining_early>0 then
  local allow={}
  for id=2,9 do allow[id]=true end
  return allow,"early"
 end
 local allow={}
 if holder~=11 and not (visited and visited[11]) then
  allow[11]=true;return allow,"penultimate_11"
 end
 if holder~=10 and not (visited and visited[10]) then
  allow[10]=true;return allow,"last_10"
 end
 return allow,"all_visited"
end
function M.resolve(bridge,selector,sample,holder,visited)
 local allowed,stage=M.allowed(visited,holder)
 local filtered={}
 for id=2,11 do
  if not allowed[id] then filtered[id]=true end
 end
 for id in pairs(visited or {}) do filtered[id]=true end
 local plan,reason,info=bridge.resolve(selector,sample,holder,filtered)
 if plan and info and info.report then
  local best,score,evaluated=Route.choose(sample,holder,filtered,info.report,stage)
  if best then
   plan.target=best.id;plan.aligned=best.aligned
   info.receiver_id=best.id;info.plan_target=best.id
   info.route_score=score;info.route_evaluated=evaluated
   info.reason="coordinate_route_selected"
  end
 end
 return plan,reason,info,stage
end
return M
