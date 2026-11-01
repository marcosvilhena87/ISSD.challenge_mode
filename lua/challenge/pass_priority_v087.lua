-- v0.8.10: route to new participants; visited players allowed only as costly relays.
local Relay=require("challenge.pass_relay_v0810")
local M={VERSION="0.8.10"}
function M.resolve(bridge,selector,sample,holder,visited,previous,consecutive)
 local target,choice,detail,stage=Relay.choose(sample,holder,visited,previous,consecutive)
 if not target then return nil,choice,{reason=choice,report=nil},stage end
 -- Validate the chosen handoff with the existing selector-to-controller bridge.
 local excluded={}
 for id=2,11 do if id~=target then excluded[id]=true end end
 local plan,reason,info=bridge.resolve(selector,sample,holder,excluded)
 if info then
  info.route_score=detail and detail.total
  info.route_evaluated=detail and {{id=target,immediate=detail.immediate,
   onward=detail.onward,total=detail.total}} or nil
  info.relay_mode=detail and detail.mode or "unknown"
  info.relay_penalty=detail and detail.penalty or 0
 end
 return plan,reason,info,stage
end
return M
