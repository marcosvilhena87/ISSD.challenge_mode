-- Challenge Gameplay Probe v1. Read-only. Canonical coordinates: ISSD.mapping/docs/RAM_MAP.md
local M={}
M.labels={START_MENU=true,LOADING=true,PLAYING_IDLE=true,PLAYING_MOVING=true,PAUSE=true,RETURN_MENU=true,OTHER=true}
local columns={"session","frame","kind","phase","sample_interval","gameplay_active","game_state","player_possession","team_possession","ball_x","ball_y","ball_moved","my_moved","cpu_moved","total_moved","valid_positions","error_count"}
for _,side in ipairs({"my","cpu"}) do
 for n=1,11 do columns[#columns+1]=side.."_p"..n.."_x";columns[#columns+1]=side.."_p"..n.."_y" end
end
local function format(v) if v==nil then return "" end return tostring(v) end
local function coords(read16,address)
 local ok,value=pcall(read16,address,"WRAM")
 if ok and type(value)=="number" and value%1==0 and value>=-32768 and value<=32767 then return value end
 return nil
end
local function byte(read,address)
 local ok,v=pcall(read,address,"WRAM")
 if ok and type(v)=="number" and v%1==0 and v>=0 and v<=255 then return v end
 return nil
end
local function word(read,address)
 local ok,v=pcall(read,address,"WRAM")
 if ok and type(v)=="number" and v%1==0 and v>=0 and v<=65535 then return v end
 return nil
end
function M.new(opts)
 assert(opts and opts.read8 and opts.read16s and opts.read16u and opts.csv and opts.session)
 local self=setmetatable({r8=opts.read8,r16s=opts.read16s,r16u=opts.read16u,csv=opts.csv,session=opts.session,previous=nil},{__index=M})
 local f=assert(io.open(self.csv,"a+"))
 if f:seek("end")==0 then f:write(table.concat(columns,",").."\n") end
 f:close()
 return self
end
function M:snapshot(frame,phase,kind,interval)
 local r={session=self.session,frame=frame,kind=kind,phase=phase,sample_interval=interval}
 r.gameplay_active=byte(self.r8,0x0006)
 r.game_state=word(self.r16u,0x00BA)
 r.player_possession=word(self.r16u,0x00A6)
 r.team_possession=byte(self.r8,0x104C)
 r.ball_x=coords(self.r16s,0x042A);r.ball_y=coords(self.r16s,0x042C)
 r.my_moved=0;r.cpu_moved=0;r.ball_moved=0;r.valid_positions=0;r.error_count=0
 local function pair(prefix,address,prev)
  local x,y=coords(self.r16s,address),coords(self.r16s,address+2)
  r[prefix.."_x"]=x;r[prefix.."_y"]=y
  if x~=nil and y~=nil then r.valid_positions=r.valid_positions+1 else r.error_count=r.error_count+1 end
  if prev and x~=nil and y~=nil and prev[prefix.."_x"]~=nil and prev[prefix.."_y"]~=nil and (x~=prev[prefix.."_x"] or y~=prev[prefix.."_y"]) then return 1 end
  return 0
 end
 local prev=self.previous
 if r.ball_x~=nil and r.ball_y~=nil then
  r.valid_positions=r.valid_positions+1
  if prev and prev.ball_x~=nil and prev.ball_y~=nil and (r.ball_x~=prev.ball_x or r.ball_y~=prev.ball_y) then r.ball_moved=1 end
 else r.error_count=r.error_count+1 end
 for n=1,11 do r.my_moved=r.my_moved+pair("my_p"..n,0x052A+(n-1)*0x100,prev) end
 for n=1,11 do r.cpu_moved=r.cpu_moved+pair("cpu_p"..n,0x102A+(n-1)*0x100,prev) end
 for _,k in ipairs({"gameplay_active","game_state","player_possession","team_possession"}) do if r[k]==nil then r.error_count=r.error_count+1 end end
 r.total_moved=r.my_moved+r.cpu_moved
 local row={}
 for i,k in ipairs(columns) do row[i]=format(r[k]) end
 local f=assert(io.open(self.csv,"a"));f:write(table.concat(row,",").."\n");f:flush();f:close()
 self.previous=r
 return r
end
M.columns=columns
return M
