-- Reconhecimento conservador: somente observacoes explicitas e validadas.
local root = _G.ISSD_PROJECT_ROOT or "."
local catalog = dofile(root .. "/lua/challenge/catalog.lua")
local M = {}
local function unknown(reason)
  return { status="unknown", challenge=nil, level=nil, source=nil, reason=reason }
end
function M.recognize(observation)
  if type(observation) ~= "table" then return unknown("no_observation") end
  local id, level = observation.challenge, observation.level
  if not catalog.get(id) then return unknown("invalid_challenge") end
  if not catalog.valid_level(level) then return unknown("invalid_level") end
  if observation.source ~= "manual" and observation.source ~= "validated_memory" then
    return unknown("untrusted_source")
  end
  return { status="identified", challenge=id, level=level, source=observation.source }
end
return M
