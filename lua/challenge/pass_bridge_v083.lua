-- PASS v0.8.3: audited handoff from geometry to the single-pass controller.
local M={VERSION="0.8.3"}
local function find(players,id)
 for _,p in ipairs(players or {}) do if p.id==id then return p end end
end
function M.resolve(selector,sample,holder,visited)
 local info={selector_version=selector and selector.VERSION or "missing",holder=holder}
 if not selector or selector.API~=3 then return nil,"selector_api_mismatch",info end
 if not sample or type(sample.players)~="table" then return nil,"missing_sample",info end
 local receiver,reason,report=selector.choose(sample,holder,visited,{tolerance=12,alignment_weight=0.25})
 info.reason=reason;info.report=report;info.receiver_id=receiver and receiver.id or nil
 if not report or type(report.eligible)~="number" then return nil,"selector_report_missing",info end
 if reason=="selected" and (not receiver or type(receiver.id)~="number") then
  return nil,"selected_without_receiver",info
 end
 if not receiver then return nil,reason or "no_receiver",info end
 if not find(sample.players,receiver.id) or receiver.id==holder then
  return nil,"receiver_not_in_sample",info
 end
 local plan={target=receiver.id,aligned=receiver.aligned}
 info.plan_target=plan.target
 return plan,"plan_valid",info
end
function M.selftest(selector,auto)
 local players={}
 for id=2,11 do players[#players+1]={id=id,x=id*20,y=0} end
 local sample={ball={x=120,y=0},players=players}
 local plan,reason,info=M.resolve(selector,sample,6,{})
 assert(reason=="plan_valid" and plan and plan.target~=6,"selector-to-plan failed: "..tostring(reason))
 assert(info.report.eligible==9,"expected nine eligible outfield receivers")
 local t=auto.new();t.enabled=true;t.button="B";t.direction="AUTO";t.start_frame=0
 local keys,state=auto.step(t,1,sample,6,{},plan,false)
 assert(state=="target_selected" and t.target==plan.target,"Auto.step rejected selected receiver")
 for frame=2,4 do
  keys,state=auto.step(t,frame,sample,6,{},plan,false)
  assert(keys.B and (keys.Up or keys.Down or keys.Left or keys.Right),
   "B and control-pad must be simultaneous")
 end
 assert(t.tries==1 and state=="pass_pulse","expected exactly one pass pulse")
 return {holder=6,eligible=info.report.eligible,target=plan.target,
  selector_version=selector.VERSION}
end
return M
