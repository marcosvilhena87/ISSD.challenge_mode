-- Standalone WRAM Cursor Discovery v1 (BizHawk / NLua).
-- Execute APENAS este script durante o experimento; nao execute main.lua em paralelo.
local function exists(p)
  local f=io.open(p,"rb");if f then f:close();return true end
  return false
end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
  if exists(p.."/lua/challenge/cursor_discovery.lua") then root=p;break end
end
assert(root,"Raiz do projeto nao encontrada. Configure o CWD para a raiz do repositorio.")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.cursor_discovery"]=nil
local discovery=require("challenge.cursor_discovery")
assert(memory and memory.read_u8 and emu and emu.framecount and emu.frameadvance,"BizHawk Lua API ausente")
local events=root.."/cursor_capture_events_v1.txt"
local results=root.."/cursor_candidates_v1.csv"
local session=os.date("!%Y%m%dT%H%M%SZ")
local offset=0
local previous=io.open(events,"rb")
if previous then offset=previous:seek("end");previous:close() end
local snaps,frames={},{}
local expected={"A","B","C","A"}
print("[ISSD.cursor_discovery] v1 session="..session.." domain=WRAM range=0x00000..0x1FFFF")
print("[ISSD.cursor_discovery] events="..events.." results="..results)
print("[ISSD.cursor_discovery] Label A = CHALLENGE START; B = KEY CONFIGURATION; C = CHANGE CONTROLLER; A = return")
print("[ISSD.cursor_discovery] Capture requests are polled per frame; hold each highlighted option stable.")
while true do
  local f=io.open(events,"rb")
  if f then
    local size=f:seek("end")
    if size<offset then offset=0 end
    f:seek("set",offset)
    while #snaps<4 do
      local start=f:seek()
      local line=f:read("*l")
      if not line then break end
      local lastpos=f:seek()
      if lastpos==size then
        local tail=io.open(events,"rb")
        if tail then
          tail:seek("set",size-1)
          local ch=tail:read(1);tail:close()
          if ch~="\n" then f:seek("set",start);break end
        end
      end
      offset=lastpos
      line=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
      local wanted=expected[#snaps+1]
      if line==wanted then
        local n=#snaps+1
        print("[ISSD.cursor_discovery] capturing "..line.." "..n.."/4...")
        snaps[n]=discovery.capture(memory.read_u8)
        frames[n]=emu.framecount()
        print("[ISSD.cursor_discovery] captured "..line.." frame="..frames[n])
        if n==4 then
          local hits=discovery.analyze(snaps)
          discovery.write_csv(results,session,frames,hits)
          print("[ISSD.cursor_discovery] matched="..#hits.." csv="..results.." (unvalidated)")
          print("[ISSD.cursor_discovery] Finished. Restart script for another independent session.")
          return
        end
      elseif line~="" then
        print("[ISSD.cursor_discovery] ignored event "..line.."; expected "..wanted)
      end
    end
    f:close()
  end
  emu.frameadvance()
end
