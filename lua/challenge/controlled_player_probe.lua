-- Controlled Player Probe v1: exploratory, read-only, no gameplay inference.
local M={}
M.labels={START_MENU=true,PLAYING_IDLE=true,MOVE_LEFT=true,MOVE_RIGHT=true,MOVE_UP=true,MOVE_DOWN=true,DRIBBLING=true,PAUSE=true,RETURN_MENU=true,OTHER=true}
M.columns={"session","frame","kind","phase","my_ptr","my_ptr_hex","my_slot","my_ptr_valid","cpu_ptr","cpu_ptr_hex","cpu_slot","cpu_ptr_valid","player_possession","possession_matches_my","team_possession_u8","team_possession_u16","game_state","my_side","cpu_side","gameplay_active","ball_x","ball_y","ball_changed","controlled_x","controlled_y","controlled_dx","controlled_dy","controlled_changed","cpu_x","cpu_y","error_count"}
local function safe(fn,addr,min,max)
 local ok,v=pcall(fn,addr,"WRAM")
 if ok and type(v)=="number" and v%1==0 and v>=min and v<=max then return v end
 return nil
end
local function ptrinfo(v,start)
 if v and v>=start and v<=start+0xA00 and (v-start)%0x100==0 then return (v-start)/0x100+1,true end
 return nil,false
end
local function hex(v) if v then return string.format("0x%04X",v) end return "" end
function M.new(opt)
 assert(opt and opt.r8 and opt.ru16 and opt.rs16 and opt.csv and opt.session)
 local self=setmetatable({r8=opt.r8,ru16=opt.ru16,rs16=opt.rs16,csv=opt.csv,session=opt.session,prev=nil},{__index=M})
 local f=assert(io.open(self.csv,"a+"))
 if f:seek("end")==0 then f:write(table.concat(M.columns,",").."\n") end
 f:close()
 return self
end
function M:sample(frame,phase,kind)
 local r={session=self.session,frame=frame,phase=phase,kind=kind,error_count=0}
 local function u8(a) local v=safe(self.r8,a,0,255);if v==nil then r.error_count=r.error_count+1 end;return v end
 local function u16(a) local v=safe(self.ru16,a,0,65535);if v==nil then r.error_count=r.error_count+1 end;return v end
 local function s16(a) local v=safe(self.rs16,a,-32768,32767);if v==nil then r.error_count=r.error_count+1 end;return v end
 r.my_ptr=u16(0x1ACC);r.cpu_ptr=u16(0x1AFC)
 r.my_ptr_hex=hex(r.my_ptr);r.cpu_ptr_hex=hex(r.cpu_ptr)
 r.my_slot,r.my_ptr_valid=ptrinfo(r.my_ptr,0x0500)
 r.cpu_slot,r.cpu_ptr_valid=ptrinfo(r.cpu_ptr,0x1000)
 r.player_possession=u16(0x00A6)
 r.possession_matches_my=(r.my_ptr_valid and r.player_possession~=nil and r.player_possession==r.my_ptr) and 1 or 0
 r.team_possession_u8=u8(0x104C);r.team_possession_u16=u16(0x104C)
 r.game_state=u16(0x00BA);r.my_side=u8(0x096E);r.cpu_side=u8(0x106E);r.gameplay_active=u8(0x0006)
 r.ball_x=s16(0x042A);r.ball_y=s16(0x042C)
 if r.my_ptr_valid then r.controlled_x=s16(r.my_ptr+0x2A);r.controlled_y=s16(r.my_ptr+0x2C) end
 if r.cpu_ptr_valid then r.cpu_x=s16(r.cpu_ptr+0x2A);r.cpu_y=s16(r.cpu_ptr+0x2C) end
 local p=self.prev
 r.ball_changed=0;r.controlled_changed=0
 if p then
  if p.ball_x and p.ball_y and r.ball_x and r.ball_y and (r.ball_x~=p.ball_x or r.ball_y~=p.ball_y) then r.ball_changed=1 end
  if p.my_ptr==r.my_ptr and p.controlled_x and p.controlled_y and r.controlled_x and r.controlled_y then
   r.controlled_dx=r.controlled_x-p.controlled_x;r.controlled_dy=r.controlled_y-p.controlled_y
   if r.controlled_dx~=0 or r.controlled_dy~=0 then r.controlled_changed=1 end
  end
 end
 local fields={}
 for i,k in ipairs(M.columns) do local v=r[k];if type(v)=="boolean" then v=v and 1 or 0 end;fields[i]=v==nil and "" or tostring(v) end
 local f=assert(io.open(self.csv,"a"));f:write(table.concat(fields,",").."\n");f:flush();f:close()
 self.prev=r
 return r
end
return M
