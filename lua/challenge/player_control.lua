-- Shared, pure player command dispatcher. No BizHawk API and no WRAM writes.
-- Challenges are isolated: only the explicitly selected policy can run.
local M={}
local allowed={Up=true,Down=true,Left=true,Right=true,A=true,B=true,X=true,Y=true,L=true,R=true,Start=true,Select=true}
local stop={invalid_read=true,not_playing=true,time_budget=true,unknown_field=true}
function M.decide(challenge,s,state,policies)
  state=state or {}
  if not state.armed then return {},"disarmed" end
  if type(challenge)~="string" or type(policies)~="table" then return {},"unknown_challenge" end
  local policy=policies[challenge]
  if type(policy)~="table" or type(policy.decide)~="function" then return {},"unknown_challenge" end
  local ok,buttons,reason=pcall(policy.decide,s,{started=state.started})
  if not ok or type(buttons)~="table" or type(reason)~="string" then return {},"policy_error" end
  for key,value in pairs(buttons) do
    if not allowed[key] or value~=true then return {},"invalid_buttons" end
  end
  return buttons,reason
end
function M.should_disarm(reason)
  return stop[reason]==true or reason=="policy_error" or reason=="invalid_buttons" or reason=="unknown_challenge"
end
return M
