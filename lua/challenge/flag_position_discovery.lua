-- DRIBBLE Flag Position Discovery v1: passive collection location evidence.
local M={}
M.header="session,frame,event,collection_index,remaining_before,remaining_after,gs,ptr,player_x,player_y,ball_x,ball_y,poss,valid_context,notes"
function M.new(o)
 assert(o and o.read8 and o.read16 and o.reads16 and o.path and o.session)
 local f=assert(io.open(o.path,"a+"));if f:seek("end")==0 then f:write(M.header.."\n") end;f:close()
 return setmetatable({o=o,previous=nil,history={},count=0},{__index=M})
end
local function safe(fn,addr)
 local ok,v=pcall(fn,addr,"WRAM")
 if ok and type(v)=="number" then return v end
end
function M:step(frame)
 local o=self.o
 local row={session=o.session,frame=frame,gs=safe(o.read16,0x00BA),ptr=safe(o.read16,0x1ACC),
  remaining_after=safe(o.read8,0x006B4),player_x=safe(o.reads16,0x0F2A),
  player_y=safe(o.reads16,0x0F2C),ball_x=safe(o.reads16,0x042A),
  ball_y=safe(o.reads16,0x042C),poss=safe(o.read16,0x00A6)}
 row.valid_context=row.gs==0 and row.ptr==0x0F00 and row.remaining_after~=nil and row.remaining_after>=0 and row.remaining_after<=5
 local old=self.previous
 local event=nil
 if row.valid_context and old and old.valid_context then
  local delta=row.remaining_after-old.remaining_after
  if delta==-1 then
   self.count=self.count+1;row.collection_index=5-row.remaining_after
   row.remaining_before=old.remaining_after;event="collection_candidate"
  elseif delta< -1 then event="skipped_multiple_or_reset";row.remaining_before=old.remaining_after
  elseif delta>0 then event="reset_or_increase";row.remaining_before=old.remaining_after end
 end
 if not old or row.valid_context~=old.valid_context then event=event or (row.valid_context and "entered_gameplay" or "left_gameplay") end
 row.event=event or "frame"
 -- Always log every frame; makes before/after reconstruction auditable.
 local values={row.session,row.frame,row.event,row.collection_index,row.remaining_before,row.remaining_after,row.gs,row.ptr,row.player_x,row.player_y,row.ball_x,row.ball_y,row.poss,row.valid_context and 1 or 0,""}
 local out={};for i,v in ipairs(values) do out[i]=v==nil and "" or tostring(v) end
 local f=assert(io.open(o.path,"a"));f:write(table.concat(out,",").."\n");f:close()
 self.previous=row
 return row
end
return M
