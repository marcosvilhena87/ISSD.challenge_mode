-- Passive probe for candidate WRAM $000DA2 My_Goal(s). No joypad writes.
-- BizHawk 2.11+; load this alongside a bot (no input control).
local root="."
local target="lua/challenge/dribble_goal_v0325.lua"
local f=io.open(root.."/"..target,"rb")
if f then f:close() else root="C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD.challenge_mode" end
local out=root.."/goal_counter_probe_v1.csv"
local events=root.."/goal_counter_events_v1.txt"
local header="frame,operator_event,da2_u16,da2_u8,da3_u8,gs_u16,remaining_u8,player_x,player_y,ball_x,ball_y,time_bcd,bonus_bcd,reason\n"
local h=assert(io.open(out,"a+"));if h:seek("end")==0 then h:write(header) end;h:close()
local function read(fn,addr) local ok,v=pcall(fn,addr,"WRAM");if ok then return v end end
local function str(v) return v==nil and "" or tostring(v) end
local function emit(s,operator,why)
 local arr={s.f,operator,s.goal,s.lo,s.hi,s.gs,s.flags,s.px,s.py,s.bx,s.by,s.time,s.bonus,why}
 for i=1,14 do arr[i]=str(arr[i]) end
 local o=assert(io.open(out,"a"));o:write(table.concat(arr,",").."\n");o:close()
end
local function sample()
 return {f=emu.framecount(),goal=read(memory.read_u16_le,0x0DA2),
  lo=read(memory.read_u8,0x0DA2),hi=read(memory.read_u8,0x0DA3),
  gs=read(memory.read_u16_le,0x00BA),flags=read(memory.read_u8,0x06B4),
  px=read(memory.read_s16_le,0x0F2A),py=read(memory.read_s16_le,0x0F2C),
  bx=read(memory.read_s16_le,0x042A),by=read(memory.read_s16_le,0x042C),
  time=read(memory.read_u8,0x14F0),bonus=read(memory.read_u8,0x14F4)}
end
local pos=0;local ef=io.open(events,"rb")
if ef then pos=ef:seek("end");ef:close() end
local previous=nil
print("[GOAL PROBE] passive $000DA2 u16 / u8; CSV="..out)
while true do
 local s=sample()
 local changed=previous and s.goal~=previous.goal
 local transition=previous and (s.gs~=previous.gs or s.flags~=previous.flags)
 if not previous or changed or transition then
  emit(s,"",not previous and "initial" or (changed and "goal_candidate_changed" or "state_transition"))
 end
 local e=io.open(events,"rb")
 if e then
  local size=e:seek("end");if size<pos then pos=0 end;e:seek("set",pos)
  while true do
   local start=e:seek();local line=e:read("*l");if not line then break end
   local after=e:seek()
   if after==size and size>0 then
    local t=io.open(events,"rb")
    if t then t:seek("set",size-1);local last=t:read(1);t:close()
     if last~="\n" then e:seek("set",start);break end
    end
   end
   pos=after
   local tag=line:gsub("\r$",""):gsub(",",";")
   if tag~="" then emit(s,tag,"operator_marker") end
  end
  e:close()
 end
 previous=s
 emu.frameadvance()
end
