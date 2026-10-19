-- v0.5: registro de transicoes, sem alegar validacao de presenca do menu.
local root=_G.ISSD_PROJECT_ROOT or "."
local recognizer=dofile(root.."/lua/challenge/recognizer.lua")
local probe=dofile(root.."/lua/challenge/memory_probe.lua")
local M={}
local function signature(s)
  return table.concat({s.status or "",s.challenge or "",tostring(s.level or ""),s.reason or "",s.source or ""},"|")
end
local function csv(v)
  if v==nil then return "" end
  return '"'..tostring(v):gsub('"','""')..'"'
end
local fields={"challenge_a","challenge_b","selected_level","legacy_level_a","legacy_level_b"}
local function log_row(file,frame,kind,current,previous,scanned)
  local raw=scanned.raw or {}
  local row={frame,kind,current.status,current.challenge,current.level,current.reason,
    current.source,previous and previous.challenge or nil,previous and previous.level or nil}
  for _,name in ipairs(fields) do row[#row+1]=raw[name] end
  for i=1,14 do row[i]=csv(row[i]) end
  file:write(table.concat(row,",").."\n")
  file:flush()
end
local function read_byte(address,domain)
  return memory.read_u8(address,domain)
end
function M.run()
  assert(emu and emu.frameadvance,"BizHawk emu.frameadvance indisponivel")
  local path=root.."/snapshots/recognizer_transitions_v05.csv"
  local file=assert(io.open(path,"ab"),"Nao foi possivel abrir CSV: "..path)
  if (file:seek("end") or 0)==0 then
    file:write("frame,event,status,challenge,level,reason,source,previous_challenge,previous_level,challenge_a,challenge_b,selected_level,legacy_level_a,legacy_level_b\n")
    file:flush()
  end
  local last_signature=nil
  local last_result=nil
  local stable_signature=nil
  local stable_count=0
  local frame=0
  print("[ISSD.challenge_mode] v0.5: telemetria em "..path)
  print("[ISSD.challenge_mode] Presenca do menu NAO VALIDADA; nao controlar jogadores.")
  while true do
    local manual=recognizer.recognize(_G.ISSD_CHALLENGE_OBSERVATION)
    local scanned=probe.read((memory and memory.read_u8) and read_byte or nil)
    local raw_key=signature(scanned)
    if scanned.status=="candidate" then
      if raw_key==stable_signature then stable_count=stable_count+1
      else stable_signature=raw_key;stable_count=1 end
    else
      stable_count=0
      stable_signature=nil
    end
    local result
    if manual.status=="identified" then result=manual
    elseif scanned.status=="candidate" and stable_count<3 then
      -- Mantem o ultimo candidato estavel somente como indicacao visual stale,
      -- sem afirmar que represente a selecao atual.
      if last_result and last_result.status=="candidate" then
        result={status="pending",challenge=last_result.challenge,level=last_result.level,
          source="previous_candidate",reason="transition_unconfirmed"}
      else
        result={status="unknown",reason="stabilizing",source="candidate_wram"}
      end
    else result=scanned end
    local key=signature(result)
    if key~=last_signature and result.status~="pending" then
      print(string.format("[ISSD.challenge_mode] %s challenge=%s level=%s source=%s reason=%s",
        result.status,tostring(result.challenge),tostring(result.level),
        tostring(result.source),tostring(result.reason)))
      local event=(scanned.status=="unknown" and (scanned.reason=="out_of_range" or
        scanned.reason=="challenge_pair_mismatch")) and "invalid_transition" or "state_change"
      log_row(file,frame,event,result,last_result,scanned)
      last_signature=key
    end
    if result.status=="candidate" then last_result=result end
    frame=frame+1
    emu.frameadvance()
  end
end
return M
