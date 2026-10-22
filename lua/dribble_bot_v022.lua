-- DRIBBLE LV.1 v0.2.2 standalone waypoint pilot. Do not run alongside another input Lua.
local function exists(p) local f=io.open(p,"rb");if f then f:close();return true end return false end
local root
for _,p in ipairs({".","..","Lua/SNES/ISSD.challenge_mode","SNES/ISSD.challenge_mode"}) do if exists(p.."/lua/challenge/dribble_waypoints_v022.lua") then root=p;break end end
assert(root,"repository root not found")
package.path=root.."/lua/?.lua;"..root.."/lua/?/init.lua;"..package.path
package.loaded["challenge.dribble_waypoints_v022"]=nil
local P=require("challenge.dribble_waypoints_v022")
assert(memory and memory.read_u8 and memory.read_u16_le and memory.read_s16_le and emu and emu.frameadvance and emu.framecount and joypad and joypad.set,"BizHawk API missing")
local events=root.."/dribble_bot_commands_v022.txt"
local outpath=root.."/dribble_bot_trace_v022.csv"
local session=os.date("!%Y%m%dT%H%M%SZ")
local f=assert(io.open(outpath,"a+"));if f:seek("end")==0 then f:write("session,frame,armed,reason,gs,ptr,remaining,target,poss,player_x,player_y,ball_x,ball_y,buttons,event\n") end;f:close()
local offset=0;local q=io.open(events,"rb");if q then offset=q:seek("end");q:close() end
local armed=false;local state=P.new()
local function release() joypad.set({},1) end
local function read(fn,a) local ok,v=pcall(fn,a,"WRAM");if ok then return v end end
local function log(s,why,keys)
 local cols={session,s.frame,armed and 1 or 0,why,s.gs,s.ptr,s.remaining,state.target,s.poss,s.px,s.py,s.bx,s.by,keys,state.event or ""}
 for i,v in ipairs(cols) do cols[i]=v==nil and "" or tostring(v) end
 local f=assert(io.open(outpath,"a"));f:write(table.concat(cols,",").."\n");f:close()
end
print("[ISSD.dribble_bot] v0.2.2 DISARMED. load alone. commands="..events.." trace="..outpath)
release()
while true do
 local cmdf=io.open(events,"rb")
 if cmdf then
  local size=cmdf:seek("end");if size<offset then offset=0 end;cmdf:seek("set",offset)
  while true do
   local pos=cmdf:seek();local line=cmdf:read("*l");if not line then break end
   local endpos=cmdf:seek()
   if endpos==size and size>0 then local tail=io.open(events,"rb");if tail then tail:seek("set",size-1);local ch=tail:read(1);tail:close();if ch~="\n" then cmdf:seek("set",pos);break end end end
   offset=endpos
   local cmd=line:gsub("\r$",""):match("^%s*(.-)%s*$"):upper()
   if cmd=="ARM" then armed=true;state=P.new();print("[ISSD.dribble_bot] v0.2.2 ARMED")
   elseif cmd=="STOP" then armed=false;release();print("[ISSD.dribble_bot] v0.2.2 STOP")
   elseif cmd~="" then print("[ISSD.dribble_bot] ignored "..cmd) end
  end
  cmdf:close()
 end
 local s={frame=emu.framecount(),gs=read(memory.read_u16_le,0x00BA),ptr=read(memory.read_u16_le,0x1ACC),remaining=read(memory.read_u8,0x006B4),poss=read(memory.read_u16_le,0x00A6),px=read(memory.read_s16_le,0x0F2A),py=read(memory.read_s16_le,0x0F2C),bx=read(memory.read_s16_le,0x042A),by=read(memory.read_s16_le,0x042C)}
 local reason=armed and "armed" or "disarmed";local keys=""
 if armed then
  local buttons
  buttons,state,reason=P.step(s,state)
  local names={};for _,k in ipairs({"Left","Right","Up","Down"}) do if buttons[k] then names[#names+1]=k end end
  keys=table.concat(names,"+")
  if state.event=="flag_collected" then print("[ISSD.dribble_bot] flag_collected frame="..s.frame.." next_target="..state.target) end
  if reason=="waypoint" or reason=="recover_ball" or reason=="precision_approach" or reason=="local_search" then joypad.set(buttons,1)
  else armed=false;release();print("[ISSD.dribble_bot] v0.2.2 auto-disarm reason="..reason.." frame="..s.frame) end
 else release() end
 if state.event=="flag_collected" or s.frame%5==0 or (reason~="waypoint" and reason~="disarmed" and reason~="precision_approach" and reason~="local_search") then log(s,reason,keys) end
 emu.frameadvance()
end
