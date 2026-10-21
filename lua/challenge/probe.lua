local M = {}
function M.decode(a, b, level)
  if type(a) ~= "number" or type(b) ~= "number" or type(level) ~= "number" then
    return {status="unknown", reason="read_failed"}
  end
  if a ~= b or a < 0 or a > 5 or level < 0 or level > 3 or a % 1 ~= 0 or level % 1 ~= 0 then
    return {status="unknown", reason="out_of_range_or_mismatch"}
  end
  local mapping = require("challenge.mapping")
  -- Sem flag validada de presenca de menu, resultado NUNCA e confirmed.
  return {status="candidate", challenge=mapping.names[a+1], challenge_id=a, level=level+1, reason="menu_presence_unverified"}
end

function M.read(read_u8)
  local map = require("challenge.mapping").addresses
  local function attempt(address)
    local ok, value = pcall(read_u8, address, "WRAM")
    if ok and type(value) == "number" then return value end
    return nil
  end
  local a, b, level = attempt(map.challenge_a), attempt(map.challenge_b), attempt(map.selected_level)
  local result = M.decode(a, b, level)
  result.raw = {challenge_a=a, challenge_b=b, selected_level=level,
    legacy_level_a=attempt(map.legacy_level_a), legacy_level_b=attempt(map.legacy_level_b)}
  return result
end
return M
