-- v0.4: interpretacao contextual; nenhum estado confirmed, sem inputs.
local M={}
local names=require("challenge.mapping").names
local screens={
  main_menu=true,mode_selection=true,input_name=true,
  challenge_selection=true,level_select=true,playing=true,
  pause=true,training=true,exit=true,other=true
}
local function csv(v) return tostring(v or ""):gsub("[\r\n,]","_") end
function M.new(path,session)
  local self=setmetatable({path=path,session=session,previous=nil},{__index=M})
  local f=assert(io.open(path,"a+"))
  if f:seek("end")==0 then
    f:write("session,frame,screen,confidence,selection,challenge,level,reason,challenge_a,challenge_b,cursor_index\n")
  end
  f:close()
  return self
end
function M:step(frame,r,phase)
  local raw=r.raw or {}
  local screen=screens[phase] and phase or "unknown"
  local selection,challenge,level,confidence,reason="","","","unknown","no_verified_screen_flag"
  local a,b,c=raw.challenge_a,raw.challenge_b,raw.selected_level
  if screen=="mode_selection" and b==255 and (c==0 or c==1) then
    selection=(c==0) and "TRAINING" or "CHALLENGE"
    confidence="candidate";reason="operator_labeled_mode_selection"
  elseif screen=="challenge_selection" and type(c)=="number" and c%1==0 and c>=0 and c<=6 then
    selection=(c==6) and "EXIT" or names[c+1]
    confidence="candidate";reason="operator_labeled_challenge_selection_cursor_only"
  elseif screen=="input_name" and type(c)=="number" then
    selection="CURSOR_"..c;confidence="candidate";reason="operator_labeled_name_input"
  elseif screen=="level_select" and r.status=="candidate" and a==b and type(c)=="number" and c>=0 and c<=3 then
    challenge=names[a+1] or "";level=c+1
    confidence="candidate";reason="operator_labeled_level_selection"
  elseif screen~="unknown" then
    reason="screen_labeled_but_values_ambiguous"
  end
  local key=table.concat({screen,confidence,tostring(selection),tostring(challenge),tostring(level),reason,tostring(a),tostring(b),tostring(c)},"|")
  if key==self.previous then return end
  self.previous=key
  local f=assert(io.open(self.path,"a"))
  local data={self.session,frame,screen,confidence,selection,challenge,level,reason,a,b,c}
  for i=1,11 do data[i]=csv(data[i]) end
  f:write(table.concat(data,",").."\n");f:close()
  print(string.format("[ISSD.challenge_mode] v0.4 screen=%s confidence=%s selection=%s challenge=%s level=%s",screen,confidence,tostring(selection),tostring(challenge),tostring(level)))
end
return M
