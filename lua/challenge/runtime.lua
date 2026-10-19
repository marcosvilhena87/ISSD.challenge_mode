local recognizer = dofile("lua/challenge/recognizer.lua")
local M = {}
local function signature(s)
  return table.concat({s.status or "", s.challenge or "", tostring(s.level or ""), s.reason or ""}, "|")
end
function M.run()
  assert(type(emu) == "table" and type(emu.frameadvance) == "function", "Execute no BizHawk com emu.frameadvance")
  local last = nil
  while true do
    local result = recognizer.recognize(_G.ISSD_CHALLENGE_OBSERVATION)
    local key = signature(result)
    if key ~= last then
      print(string.format("[ISSD.challenge_mode] %s challenge=%s level=%s source=%s reason=%s",
        result.status, tostring(result.challenge), tostring(result.level),
        tostring(result.source), tostring(result.reason)))
      last = key
    end
    emu.frameadvance()
  end
end
return M
