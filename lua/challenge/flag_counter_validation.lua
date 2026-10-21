-- DRIBBLE Flag Counter Validation v1. Read-only, per-frame observations.
local M={}
M.addresses={remaining=0x006B4,alternate_up=0x00F2B,alternate_down=0x00EE9}
M.labels={START_MENU=true,PLAYING=true,NO_COLLECTION=true,FLAG_COLLECTED=true,SUCCESS=true,FAILURE=true,RETURN_MENU=true,OTHER=true}
M.columns={"session","frame","kind","operator_label","game_state","controlled_pointer","remaining_06b4","delta_06b4","alternate_0f2b","delta_0f2b","alternate_0ee9","delta_0ee9","player_x","player_y","ball_x","ball_y","candidate_phase","read_errors"}
local function read(fn,addr,min,max)
 local ok,v=pcall(fn,addr,"WRAM")
 if ok and type(v)=="number" and v%1==0 and v>=min and v<=max then return v end
 return nil
end
function M.new(o)
 assert(o and o.u8 and o.u16 and o.s16 and o.csv and o.session)
 local f=assert(io.open(o.csv,"a+"));if f:seek("end")==0 then f:write(table.concat(M.columns,",").."\n") end;f:close()
 return setmetatable({o=o,prev=nil},{__index=M})
end
function M:sample(frame,kind,label)
 local o=self.o
 local r={session=o.session,frame=frame,kind=kind,operator_label=label,read_errors=0}
 local function pull(k,fn,addr,lo,hi)
  r[k]=read(fn,addr,lo,hi)
  if r[k]==nil then r.read_errors=r.read_errors+1 end
 end
 pull("game_state",o.u16,0x00BA,0,65535)
 pull("controlled_pointer",o.u16,0x1ACC,0,65535)
 pull("remaining_06b4",o.u8,M.addresses.remaining,0,255)
 pull("alternate_0f2b",o.u8,M.addresses.alternate_up,0,255)
 pull("alternate_0ee9",o.u8,M.addresses.alternate_down,0,255)
 pull("player_x",o.s16,0x0F2A,-32768,32767)
 pull("player_y",o.s16,0x0F2C,-32768,32767)
 pull("ball_x",o.s16,0x042A,-32768,32767)
 pull("ball_y",o.s16,0x042C,-32768,32767)
 r.candidate_phase=(r.game_state==0 and r.controlled_pointer==0x0F00) and "playing_candidate" or "outside_playing_candidate"
 local p=self.prev
 for _,pair in ipairs({{"remaining_06b4","delta_06b4"},{"alternate_0f2b","delta_0f2b"},{"alternate_0ee9","delta_0ee9"}}) do
  if p and r[pair[1]]~=nil and p[pair[1]]~=nil then r[pair[2]]=r[pair[1]]-p[pair[1]] end
 end
 local row={}
 for i,k in ipairs(M.columns) do row[i]=r[k]==nil and "" or tostring(r[k]) end
 local f=assert(io.open(o.csv,"a"));f:write(table.concat(row,",").."\n");f:close()
 self.prev=r
 return r
end
return M
