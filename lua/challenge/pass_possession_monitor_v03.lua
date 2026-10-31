-- PASS v0.3: monitor an unverified possession word without claiming player identity.
-- Pure Lua, independent of BizHawk.
local M={}
function M.new(opts)
 opts=opts or {}
 local self={last=nil,count=0,stable=nil,first=nil,changes=0,unknown=0,
  minimum=opts.minimum or 3,events={}}
 function self:step(frame,raw,player_id)
  if type(raw)~="number" or raw%1~=0 or raw<0 or raw>65535 then
   self.last=nil;self.count=0;self.unknown=self.unknown+1
   return nil
  end
  if raw==self.last then self.count=self.count+1
  else self.last=raw;self.count=1 end
  if self.count<self.minimum or raw==self.stable then return nil end
  local prev=self.stable
  self.stable=raw
  local event={frame=frame,previous=prev,current=raw,player_id=player_id,
   kind=prev==nil and "initial_stable_value" or "stable_value_change",
   evidence="unverified_possession_candidate"}
  if prev~=nil then self.changes=self.changes+1 end
  self.events[#self.events+1]=event
  return event
 end
 return self
end
return M
