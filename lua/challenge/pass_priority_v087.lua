-- v0.8.20 strict requested sequence; no fallback to arbitrary teammate.
local Ordered=require("challenge.pass_ordered_v0820")
local Feet=require("challenge.pass_feet_v0815")
local M={VERSION="0.8.20"}
function M.resolve(bridge,selector,sample,holder,visited,previous,consecutive,excluded,route_index)
 local target,why=Ordered.next(route_index,holder)
 if not target then return nil,why,{reason=why,report=nil},"ordered" end
 local safe,reason,geometry=Feet.check(sample,holder,target)
 if not safe then
  return nil,"approach_required",{reason=reason,target=target,geometry=geometry,report=nil},"ordered"
 end
 local exclusion={}
 for id=2,11 do if id~=target then exclusion[id]=true end end
 local plan,bridge_reason,info=bridge.resolve(selector,sample,holder,exclusion)
 if info then
  info.route_score=geometry and geometry.distance
  info.route_evaluated=geometry and {{id=target,immediate=geometry.distance,onward=0,total=geometry.distance}} or nil
  info.relay_mode="ordered"
 end
 return plan,bridge_reason,info,"ordered"
end
return M
