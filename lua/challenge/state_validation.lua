-- DRIBBLE LV.1 state validation v1; observations only.
local M={}
M.labels={PLAYING=true,SUCCESS=true,FAILURE=true,RETURN_MENU=true,START_MENU=true,TRANSITION=true,UNKNOWN=true}
M.columns={"session","frame","kind","operator_label","game_state","my_controlled_player","my_pointer_hex","player_possession","gameplay_active","field_length","field_width","ball_x","ball_y","player11_x","player11_y","state_changed","pointer_changed","field_changed","candidate_state","read_errors"}
local function safe(fn,address,min,max)
 local ok,v=pcall(fn,address,"WRAM")
 if ok and type(v)=="number" and v%1==0 and v>=min and v<=max then return v end
 return nil
end
function M.classify(r)
 if r.game_state==0 and r.my_controlled_player==0x0F00 then return "possible_playing" end
 if r.game_state==5 then return "possible_transition" end
 if r.game_state==6 and r.my_controlled_player==0x0F00 then return "possible_transition" end
 if r.game_state==6 and r.my_controlled_player==0 then return "possible_post_game_or_menu" end
 return "unknown"
end
function M.new(o)
 assert(o and o.r8 and o.ru16 and o.rs16 and o.csv and o.session)
 local f=assert(io.open(o.csv,"a+"));if f:seek("end")==0 then f:write(table.concat(M.columns,",").."\n") end;f:close()
 return setmetatable({o=o,previous=nil},{__index=M})
end
function M:sample(frame,kind,label)
 local o=self.o
 local r={session=o.session,frame=frame,kind=kind,operator_label=label,read_errors=0}
 local function read(k,fn,addr,lo,hi)
  r[k]=safe(fn,addr,lo,hi)
  if r[k]==nil then r.read_errors=r.read_errors+1 end
 end
 read("game_state",o.ru16,0x00BA,0,65535)
 read("my_controlled_player",o.ru16,0x1ACC,0,65535)
 read("player_possession",o.ru16,0x00A6,0,65535)
 read("gameplay_active",o.r8,0x0006,0,255)
 read("field_length",o.ru16,0x12A2,0,65535)
 read("field_width",o.ru16,0x12A4,0,65535)
 read("ball_x",o.rs16,0x042A,-32768,32767)
 read("ball_y",o.rs16,0x042C,-32768,32767)
 read("player11_x",o.rs16,0x0F2A,-32768,32767)
 read("player11_y",o.rs16,0x0F2C,-32768,32767)
 r.my_pointer_hex=r.my_controlled_player and string.format("0x%04X",r.my_controlled_player) or ""
 local p=self.previous
 r.state_changed=p and r.game_state~=p.game_state and 1 or 0
 r.pointer_changed=p and r.my_controlled_player~=p.my_controlled_player and 1 or 0
 r.field_changed=p and (r.field_length~=p.field_length or r.field_width~=p.field_width) and 1 or 0
 r.candidate_state=M.classify(r)
 local row={}
 for i,k in ipairs(M.columns) do row[i]=r[k]==nil and "" or tostring(r[k]) end
 local f=assert(io.open(o.csv,"a"));f:write(table.concat(row,",").."\n");f:close()
 self.previous=r
 return r
end
return M
