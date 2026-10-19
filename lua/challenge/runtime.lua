local root = _G.ISSD_PROJECT_ROOT or "."
local recognizer = dofile(root .. "/lua/challenge/recognizer.lua")
local probe = dofile(root .. "/lua/challenge/memory_probe.lua")
local M = {}
local function signature(s)
  return table.concat({s.status or "", s.challenge or "", tostring(s.level or ""), s.reason or "", s.source or ""}, "|")
end
local function read_byte(address, domain)
  return memory.read_u8(address, domain)
end
function M.run()
  assert(type(emu) == "table" and type(emu.frameadvance) == "function", "Execute no BizHawk com emu.frameadvance")
  local last, stable_key, stable_count = nil, nil, 0
  while true do
    local manual = recognizer.recognize(_G.ISSD_CHALLENGE_OBSERVATION)
    local scanned = probe.read((memory and memory.read_u8) and read_byte or nil)
    local result
    if manual.status == "identified" then
      result=manual -- Fonte manual explicita tem prioridade sobre sondas candidatas.
    else
      local key = signature(scanned)
      if scanned.status=="candidate" and key==stable_key then
        stable_count=stable_count+1
      else
        stable_key=key
        stable_count=scanned.status=="candidate" and 1 or 0
      end
      -- Tres leituras consistentes reduzem instabilidade, mas NAO validam modo.
      if scanned.status=="candidate" and stable_count<3 then
        result={status="unknown",reason="stabilizing",source="candidate_wram"}
      else
        result=scanned
      end
    end
    local key=signature(result)
    if key~=last then
      print(string.format("[ISSD.challenge_mode] %s challenge=%s level=%s source=%s reason=%s",
        result.status,tostring(result.challenge),tostring(result.level),
        tostring(result.source),tostring(result.reason)))
      last=key
    end
    emu.frameadvance()
  end
end
return M
