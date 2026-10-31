-- PASS LV.1 v0.5: read-only timer transition observer.
-- Timing addresses inherited from DRIBBLE; PASS interpretation requires live validation.
local M={}
local function bcd(v)
 if type(v)~="number" or v<0 or v>255 then return nil end
 local lo=v%16;local hi=math.floor(v/16)
 if lo>9 or hi>9 then return nil end
 return hi*10+lo
end
function M.read(u8,u16)
 local function safe(fn,addr)
  local ok,v=pcall(fn,addr,"WRAM")
  if ok and type(v)=="number" then return v end
 end
 local time_raw=safe(u8,0x014F0)
 local bonus_raw=safe(u8,0x014F4)
 return {time_raw=time_raw,time=bcd(time_raw),time_frac=safe(u16,0x014F2),
  bonus_raw=bonus_raw,bonus=bcd(bonus_raw),bonus_frac=safe(u16,0x014F6)}
end
function M.new()
 local t={previous=nil,bonus_active=false,bonus_activation_frame=nil,events={}}
 function t:step(s,frame)
  local p=self.previous
  self.previous=s
  if not s or not p then return nil end
  local event=nil
  -- Detect transition from a zero bonus counter to a positive one.
  -- This is a candidate: initial nonzero or already-running bonus is not an activation.
  if not self.bonus_active and p.bonus==0 and s.bonus and s.bonus>0 then
   self.bonus_active=true
   self.bonus_activation_frame=frame
   event={kind="bonus_zero_to_positive_candidate",frame=frame}
  elseif p.bonus~=nil and s.bonus~=nil and p.bonus~=s.bonus then
   event={kind="bonus_value_change",frame=frame}
  elseif p.time~=nil and s.time~=nil and p.time~=s.time then
   event={kind="main_time_change",frame=frame}
  end
  if event then
   event.time=s.time;event.bonus=s.bonus;event.time_frac=s.time_frac
   event.bonus_frac=s.bonus_frac
   self.events[#self.events+1]=event
  end
  return event
 end
 return t
end
return M
