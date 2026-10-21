-- DRIBBLE LV.1 Focused Probe v1: observational, read-only WRAM.
local M={}
M.columns={"session","frame","sample_kind","elapsed_frames","elapsed_seconds_60fps","gameplay_active_u8","gameplay_active_u16","game_state","stadium_id","ball_x_s16","ball_y_s16","ball_x_u16","ball_y_u16","player11_x","player11_y","field_length","field_width","center_x","center_y","ball_dx","ball_dy","player_dx","player_dy","distance_sq","distance","ball_changed","player_changed","read_errors"}
local function read(fn,addr,lo,hi)
 local ok,v=pcall(fn,addr,"WRAM")
 if ok and type(v)=="number" and v%1==0 and v>=lo and v<=hi then return v end
 return nil
end
function M.new(opt)
 assert(opt and opt.r8 and opt.ru16 and opt.rs16 and opt.csv and opt.session)
 local self=setmetatable({opt=opt,prev=nil,start=nil},{__index=M})
 local f=assert(io.open(opt.csv,"a+"));if f:seek("end")==0 then f:write(table.concat(M.columns,",").."\n") end;f:close()
 return self
end
function M:sample(frame,kind)
 if not self.start then self.start=frame end
 local r={session=self.opt.session,frame=frame,sample_kind=kind,elapsed_frames=frame-self.start,elapsed_seconds_60fps=string.format("%.3f",(frame-self.start)/60),read_errors=0}
 local function pull(k,fn,addr,lo,hi)
  r[k]=read(fn,addr,lo,hi)
  if r[k]==nil then r.read_errors=r.read_errors+1 end
 end
 local o=self.opt
 pull("gameplay_active_u8",o.r8,0x0006,0,255)
 pull("gameplay_active_u16",o.ru16,0x0006,0,65535)
 pull("game_state",o.ru16,0x00BA,0,65535)
 pull("stadium_id",o.rs16,0x0086,-32768,32767)
 pull("ball_x_s16",o.rs16,0x042A,-32768,32767)
 pull("ball_y_s16",o.rs16,0x042C,-32768,32767)
 pull("ball_x_u16",o.ru16,0x042A,0,65535)
 pull("ball_y_u16",o.ru16,0x042C,0,65535)
 pull("player11_x",o.rs16,0x0F2A,-32768,32767)
 pull("player11_y",o.rs16,0x0F2C,-32768,32767)
 pull("field_length",o.ru16,0x12A2,0,65535)
 pull("field_width",o.ru16,0x12A4,0,65535)
 pull("center_x",o.ru16,0x12F2,0,65535)
 pull("center_y",o.ru16,0x12D8,0,65535)
 local p=self.prev
 r.ball_changed=0;r.player_changed=0
 if p then
  if p.ball_x_s16 and r.ball_x_s16 and p.ball_y_s16 and r.ball_y_s16 then
   r.ball_dx=r.ball_x_s16-p.ball_x_s16;r.ball_dy=r.ball_y_s16-p.ball_y_s16
   if r.ball_dx~=0 or r.ball_dy~=0 then r.ball_changed=1 end
  end
  if p.player11_x and r.player11_x and p.player11_y and r.player11_y then
   r.player_dx=r.player11_x-p.player11_x;r.player_dy=r.player11_y-p.player11_y
   if r.player_dx~=0 or r.player_dy~=0 then r.player_changed=1 end
  end
 end
 if r.ball_x_s16 and r.ball_y_s16 and r.player11_x and r.player11_y then
  local dx=r.ball_x_s16-r.player11_x;local dy=r.ball_y_s16-r.player11_y
  r.distance_sq=dx*dx+dy*dy;r.distance=string.format("%.3f",math.sqrt(r.distance_sq))
 end
 local vals={}
 for i,k in ipairs(M.columns) do vals[i]=r[k]==nil and "" or tostring(r[k]) end
 local f=assert(io.open(o.csv,"a"));f:write(table.concat(vals,",").."\n");f:flush();f:close()
 self.prev=r
 return r
end
return M
