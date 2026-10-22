-- Append-only command file reader. Existing lines are ignored at startup.
-- This module does not depend on BizHawk or the controller.
local M={}
function M.new(path,logger)
 local pos=0
 local initial=io.open(path,"rb")
 if initial then pos=initial:seek("end") or 0;initial:close() end
 local consumed=0
 local count=0
 local function poll(handle)
  count=count+1
  local cf=io.open(path,"rb")
  if cf then
   local size=cf:seek("end") or 0
   if size<pos then
    logger("command file truncated; cursor reset from "..pos.." to 0")
    pos=0
   end
   cf:seek("set",pos)
   local chunk=cf:read("*a") or ""
   cf:close()
   local last_newline=chunk:match(".*()\n")
   if last_newline then
    local complete=chunk:sub(1,last_newline)
    pos=pos+last_newline
    consumed=consumed+last_newline
    for raw in complete:gmatch("([^\n]*)\n") do
     local line=raw:gsub("^\239\187\191",""):gsub("\r$",""):match("^%s*(.-)%s*$")
     if line~="" then handle(line) end
    end
   end
  end
  if count%600==0 then
   local z=io.open(path,"rb")
   local size=-1
   if z then size=z:seek("end") or -1;z:close() end
   logger("command poll cursor="..pos.." file_bytes="..size.." consumed="..consumed)
  end
 end
 return {poll=poll}
end
return M
