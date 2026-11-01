-- PASS v0.8.66: stadium-derived goal-center candidate, read-only WRAM.
local M={VERSION="0.8.66",ATTACK_SIDE="right"}
local function read(fn,addr)
 local ok,v=pcall(fn,addr,"WRAM")
 if ok and type(v)=="number" and v==v and v>=0 and v<=65535 then return v end
end
function M.read(s16,u16)
 local id=read(s16,0x0086)
 local len=read(u16,0x12A2)
 local width=read(u16,0x12A4)
 local cx=read(u16,0x12F2)
 local cy=read(u16,0x12D8)
 if not id or id<0 or id>7 or not len or not width or not cx or not cy then return nil,"stadium_map_invalid" end
 if len==0 or width==0 then return nil,"stadium_dimensions_zero" end
 -- Endpoint is a candidate until field units and attacking orientation are calibrated.
 return {stadium=id,field_length=len,field_width=width,center_x=cx,center_y=cy,
   left_x=cx-len/2,right_x=cx+len/2,attack_side=M.ATTACK_SIDE,
   x=cx+len/2,y=cy,calibrated=false}
end
return M
