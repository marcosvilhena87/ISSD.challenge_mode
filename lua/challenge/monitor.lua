-- v0.3: registra TODAS as transicoes observadas; nao identifica presenca de menu.
local M = {}
local keys = {"challenge_a","challenge_b","selected_level","legacy_level_a","legacy_level_b"}
local function clean(s)
  return tostring(s or ""):gsub("[\r\n,]","_")
end
local function raw_key(raw)
  local a = {}
  for _, k in ipairs(keys) do a[#a+1] = tostring(raw[k]) end
  return table.concat(a, ":")
end
function M.new(opts)
  assert(opts and opts.read and opts.csv and opts.frame, "monitor requires read, csv and frame")
  local self = {read=opts.read, frame=opts.frame, csv=opts.csv,
    events=opts.events, context=opts.context, phase="unlabeled", previous=nil, since=nil,
    session=opts.session or os.date("!%Y%m%dT%H%M%SZ"), event_offset=0}
  local f = assert(io.open(self.csv, "a+"))
  local size = f:seek("end")
  if size == 0 then
    f:write("session,frame,kind,phase,event,status,reason,challenge_id,challenge,level,challenge_a,challenge_b,selected_level,legacy_level_a,legacy_level_b,previous_duration_frames\n")
  end
  f:close()
  -- Ignore old operator events from earlier launches.
  if self.events then
    local ef = io.open(self.events,"rb")
    if ef then self.event_offset=ef:seek("end"); ef:close() end
  end
  return setmetatable(self,{__index=M})
end
function M:emit(frame, kind, event, r, duration)
  local raw=r.raw
  local fields={self.session,frame,kind,self.phase,event,r.status,r.reason,r.challenge_id,
    r.challenge,r.level,raw.challenge_a,raw.challenge_b,raw.selected_level,
    raw.legacy_level_a,raw.legacy_level_b,duration}
  for i=1,#fields do fields[i]=clean(fields[i]) end
  -- ipairs would stop at nil; use fixed column count
  local out={}
  for i=1,16 do out[i]=clean(fields[i]) end
  local f=assert(io.open(self.csv,"a"))
  f:write(table.concat(out,",").."\n")
  f:flush()
  f:close()
end
function M:poll_events(frame,r)
  if not self.events then return end
  local f=io.open(self.events,"rb")
  if not f then return end
  local size=f:seek("end")
  if size < self.event_offset then self.event_offset=0 end
  f:seek("set",self.event_offset)
  while true do
    local start=f:seek()
    local line=f:read("*l")
    if not line then break end
    -- Only consume complete lines, to avoid racing with PowerShell writer.
    if f:seek() == size and size > 0 then
      local check=io.open(self.events,"rb")
      if check then
        check:seek("set",size-1)
        local last=check:read(1)
        check:close()
        if last ~= "\n" then f:seek("set",start); break end
      end
    end
    line=line:gsub("\r$",""):match("^%s*(.-)%s*$")
    if line ~= "" then
      local allowed={menu=true,level_select=true,playing=true,pause=true,exit=true,main_menu=true,training=true,other=true,mode_selection=true,input_name=true,challenge_selection=true}
      if allowed[line] then self.phase=line else line="note_"..clean(line) end
      self:emit(frame,"operator",line,r,"")
      print("[ISSD.challenge_mode] operator "..line.." frame="..frame)
    end
  end
  self.event_offset=f:seek()
  f:close()
end
function M:step()
  local frame=self.frame()
  local r=self.read()
  local key=raw_key(r.raw)
  if key ~= self.previous then
    local duration=self.since and (frame-self.since) or ""
    self:emit(frame,"transition","",r,duration)
    print(string.format("[ISSD.challenge_mode] frame=%s %s challenge=%s level=%s a=%s b=%s selected_level=%s phase=%s",
      frame,r.status,tostring(r.challenge),tostring(r.level),tostring(r.raw.challenge_a),
      tostring(r.raw.challenge_b),tostring(r.raw.selected_level),self.phase))
    self.previous=key
    self.since=frame
  end
  self:poll_events(frame,r)
  if self.context then self.context:step(frame,r,self.phase) end
end
return M
