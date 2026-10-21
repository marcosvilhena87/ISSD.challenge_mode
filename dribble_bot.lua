-- Experimental DRIBBLE LV.1 bot. Run ALONE; manual ARM required.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do
 if exists(p.."/lua/challenge/dribble_bot.lua") then root=p;break end
end
assert(root,"Project root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.dribble_bot"]=nil
package.loaded["challenge.player_control"]=nil
local policy=require("challenge.dribble_bot")
local controller=require("challenge.player_control")
local policies={DRIBBLE=policy}
assert(memory and memory.read_u16_le and memory.read_s16_le and emu and emu.framecount and emu.frameadvance and joypad and joypad.set,"BizHawk API unavailable")
local events=root.."/dribble_bot_commands_v01.txt"
local csv=root.."/dribble_bot_trace_v01.csv"
local f=assert(io.open(csv,"a+"))
if f:seek("end")==0 then f:write("session,frame,armed,reason,gs,ptr,poss,player_x,player_y,ball_x,ball_y,buttons\n") end;f:close()
local offset=0;local f0=io.open(events,"rb");if f0 then offset=f0:seek("end");f0:close() end
local armed=false;local started=nil;local session=os.date("!%Y%m%dT%H%M%SZ")
local function release() joypad.set({},1) end
local function u16(a) local ok,v=pcall(memory.read_u16_le,a,"WRAM");if ok and type(v)=="number" then return v end end
local function s16(a) local ok,v=pcall(memory.read_s16_le,a,"WRAM");if ok and type(v)=="number" then return v end end
print("[ISSD.dribble_bot] v0.1 EXPERIMENTAL. Rightward direction not validated. csv="..csv)
print("[ISSD.dribble_bot] DISARMED. Add-Content .\\dribble_bot_commands_v01.txt 'ARM' when challenge begins; 'STOP' at any time.")
release()
while true do
 local f=io.open(events,"rb")
 if f then
  local size=f:seek("end");if size<offset then offset=0 end;f:seek("set",offset)
  while true do
   local pos=f:seek();local line=f:read("*l");if not line then break end
   local endpos=f:seek()
   if endpos==size and size>0 then
    local tail=io.open(events,"rb")
    if tail then tail:seek("set",size-1);local ch=tail:read(1);tail:close();if ch~="\n" then f:seek("set",pos);break end end
   end
   offset=endpos
   local cmd=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if cmd=="ARM" then armed=true;started=emu.framecount();print("[ISSD.dribble_bot] ARMED frame="..started)
   elseif cmd=="STOP" then armed=false;started=nil;release();print("[ISSD.dribble_bot] STOP frame="..emu.framecount())
   elseif cmd~="" then print("[ISSD.dribble_bot] ignored "..cmd) end
  end
  f:close()
 end
 local frame=emu.framecount()
 local s={frame=frame,game_state=u16(0x00BA),ptr=u16(0x1ACC),possession=u16(0x00A6),player_x=s16(0x0F2A),player_y=s16(0x0F2C),ball_x=s16(0x042A),ball_y=s16(0x042C),field_length=u16(0x12A2)}
 local buttons,reason={},armed and "waiting" or "disarmed"
 if armed then
  buttons,reason=controller.decide("DRIBBLE",s,{armed=armed,started=started},policies)
  if controller.should_disarm(reason) then
   armed=false;release()
   print("[ISSD.dribble_bot] auto DISARM reason="..reason.." frame="..frame)
  else joypad.set(buttons,1) end
 else release() end
 if frame%10==0 or reason=="time_budget" then
  local keys={}
  for _,k in ipairs({"Left","Right","Up","Down"}) do if buttons[k] then keys[#keys+1]=k end end
  local row={session,frame,armed and 1 or 0,reason,s.game_state,s.ptr,s.possession,s.player_x,s.player_y,s.ball_x,s.ball_y,table.concat(keys,"+")}
  for i,v in ipairs(row) do row[i]=v==nil and "" or tostring(v) end
  local out=assert(io.open(csv,"a"));out:write(table.concat(row,",").."\n");out:close()
 end
 emu.frameadvance()
end
