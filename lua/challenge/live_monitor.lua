-- Monitor passivo do menu Challenge Mode (BizHawk SNES).
-- Use somente no menu, mudando UMA variavel por vez entre capturas.
local M={}
local root=_G.ISSD_PROJECT_ROOT or "."
local domain="WRAM"
local size=0x20000
local previous=nil
local baseline=nil
local sequence=0
local folder=root.."/snapshots"
local outfile=folder.."/live_menu_changes.csv"
local function read_ram()
  local bytes={}
  for i=0,size-1 do bytes[i+1]=memory.read_u8(i,domain) end
  return bytes
end
local function csv(s)
  s=tostring(s or ""):gsub('"','""')
  return '"'..s..'"'
end
local function diff(before,after,label)
  local count=0
  local rows={}
  for i=1,size do
    if before[i]~=after[i] then
      count=count+1
      rows[#rows+1]=string.format("%d,%s,0x%05X,%d,%d,%d\n",
        sequence,csv(label),i-1,i-1,before[i],after[i])
    end
  end
  local f=assert(io.open(outfile,"ab"))
  for _,line in ipairs(rows) do f:write(line) end
  f:close()
  print(string.format("[LIVE WRAM] %s: %d bytes alterados. CSV=%s",label,count,outfile))
  return count
end
function M.run()
  assert(emu and emu.frameadvance and memory and memory.read_u8,"Requer BizHawk SNES com API de memoria")
  assert(forms and forms.newform and forms.button,"Requer BizHawk Forms")
  if memory.getmemorydomainsize then
    assert(memory.getmemorydomainsize(domain)>=size,"WRAM menor que 128 KiB")
  end
  local test=assert(io.open(folder.."/.live_write_test","wb"),"Crie a pasta snapshots")
  test:close();os.remove(folder.."/.live_write_test")
  local exists=io.open(outfile,"rb")
  if exists then exists:close() else
    local f=assert(io.open(outfile,"wb"))
    f:write("capture,label,address_hex,address_dec,before,after\n");f:close()
  end
  local pending=nil
  local window=forms.newform(520,205,"ISSD WRAM Live Monitor")
  forms.label(window,"Capture referencia; mude apenas desafio OU nivel; compare.",10,10,495,28)
  forms.button(window,"Referencia",function() pending="baseline" end,10,50,150,35)
  forms.button(window,"Mudou desafio",function() pending="challenge" end,175,50,150,35)
  forms.button(window,"Mudou nivel",function() pending="level" end,340,50,150,35)
  forms.button(window,"Outra mudanca",function() pending="other" end,10,105,150,35)
  forms.button(window,"Nova referencia",function() pending="baseline" end,175,105,150,35)
  print("[LIVE WRAM] Referencia primeiro. Compare apos alterar apenas uma opcao.")
  print("[LIVE WRAM] CSV: "..outfile)
  while true do
    if pending then
      local action=pending;pending=nil
      local current=read_ram()
      if action=="baseline" then
        baseline=current;previous=current
        print("[LIVE WRAM] Referencia registrada (128 KiB).")
      elseif not previous then
        print("[LIVE WRAM] Primeiro capture Referencia.")
      else
        sequence=sequence+1
        diff(previous,current,action)
        previous=current
      end
    end
    emu.frameadvance()
  end
end
return M
