-- Snapshot WRAM 128 KiB, sem modificar memoria ou pressionar botoes no jogo.
-- No Lua Console do BizHawk execute: dofile("lua/challenge/wram_scanner.lua").run()
-- F6: proximo caso (duas rodadas de 24). F7: baseline fora do desafio.
local M = {}
local root = _G.ISSD_PROJECT_ROOT or [[C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/ISSD.challenge_mode-main]]
local snapshots_root = root .. "/snapshots"
local snapshot_dir = nil
local ids = {"dribble","pass","shoot","defense","corner_kick","free_kick"}
local size = 0x20000
local function hex(bytes)
  return (bytes:gsub(".", function(c) return string.format("%02X", string.byte(c)) end))
end
local function read()
  assert(memory and memory.read_u8, "BizHawk memory.read_u8 necessario")
  if memory.getmemorydomainsize then
    assert(memory.getmemorydomainsize("WRAM") >= size, "WRAM menor que 128 KiB")
  end
  local chunks, part = {}, {}
  -- Preferir leitura de byte, que evita suposicoes sobre string API entre versoes.
  for address=0,size-1 do
    part[#part+1] = string.char(memory.read_u8(address, "WRAM"))
    if #part == 4096 then chunks[#chunks+1] = table.concat(part); part={} end
  end
  if #part>0 then chunks[#chunks+1]=table.concat(part) end
  return table.concat(chunks)
end
local function exists(path)
  local f=io.open(path,"rb"); if f then f:close();return true end;return false
end
local function ensure_root()
  local f,err=io.open(snapshots_root .. "/.write_test","wb")
  if not f then error("Crie a pasta snapshots/ na raiz do repositorio: "..tostring(err)) end
  f:close()
  os.remove(snapshots_root .. "/.write_test")
end
local function new_session()
  ensure_root()
  local timestamp=os.date("%Y%m%d_%H%M%S")
  for n=1,999 do
    local suffix=n==1 and "" or string.format("_%03d",n)
    local dir=snapshots_root .. "/session_" .. timestamp .. suffix
    -- Em Windows/BizHawk os.execute cria a pasta; a verificacao abaixo
    -- impede reutilizar uma sessao ja iniciada no mesmo segundo.
    if not exists(dir .. "/manifest.csv") then
      local cmd='mkdir "' .. dir:gsub("/", "\\") .. '" 2>nul'
      os.execute(cmd)
      local test=io.open(dir .. "/.write_test","wb")
      if test then
        test:close()
        os.remove(dir .. "/.write_test")
        return dir
      end
    end
  end
  error("Nao foi possivel criar uma pasta de sessao gravavel")
end
local function append(path,s)
  local f=assert(io.open(path,"ab")); f:write(s);f:close()
end
function M.capture(name, challenge, level, round)
  assert(name:match("^[%w_%-]+$"), "nome inseguro")
  local path=snapshot_dir.."/"..name..".hex"
  assert(not exists(path), "snapshot ja existe: "..path)
  local bytes=read()
  local f=assert(io.open(path,"wb"));f:write(hex(bytes),"\n");f:close()
  append(snapshot_dir.."/manifest.csv", table.concat({name,challenge or "outside",tostring(level or 0),tostring(round or 0)},",").."\n")
  print(string.format("[WRAM] %s %d bytes (%s LV%s rodada %s)",name,#bytes,challenge or "outside",tostring(level or 0),tostring(round or 0)))
end
function M.run()
  assert(emu and emu.frameadvance and input and input.get, "BizHawk emu.frameadvance e input.get necessarios")
  snapshot_dir = new_session()
  print("[WRAM] Sessao: " .. snapshot_dir)
  append(snapshot_dir.."/manifest.csv","name,challenge,level,round\n")
  local index,prev6,prev7=0,false,false
  print("[WRAM] Inicie FORA do desafio: F7 = baseline. F6 = proximo caso da sequencia.")
  print("[WRAM] Ordem: DRIBBLE LV1..4, PASS LV1..4, SHOOT, DEFENSE, CORNER_KICK, FREE_KICK; repita 2 rodadas.")
  while true do
    local keys=input.get()
    local f6=not not keys.F6
    local f7=not not keys.F7
    if f7 and not prev7 then
      M.capture("outside",nil,nil,nil)
    end
    if f6 and not prev6 then
      if index < 48 then
        index=index+1
        local round=math.floor((index-1)/24)+1
        local position=(index-1)%24
        local challenge=ids[math.floor(position/4)+1]
        local level=position%4+1
        local name=string.format("r%d_%s_lv%d",round,challenge,level)
        M.capture(name,challenge,level,round)
        if index<48 then print("[WRAM] Proxima captura: "..ids[math.floor(((index)%24)/4)+1].." LV"..(((index)%4)+1)) end
      else print("[WRAM] 48 capturas concluidas. Execute lua tests/test_wram_analyzer.lua e lua lua/analyze_snapshots.lua fora do BizHawk.") end
    end
    prev6,prev7=f6,f7
    emu.frameadvance()
  end
end
return M
