-- CSV schema setup and append logic shared by the DRIBBLE runner.
-- Preserve header repair, backup policy and explicit nil-safe fields.
local M={}
local function csv_columns(line)
 local _,commas=line:gsub(",","")
 return commas+1
end
function M.setup(path,header)
 local f=io.open(path,"rb")
 if not f then
  local created=assert(io.open(path,"wb"));created:write(header.."\n");created:close()
  return
 end
 local raw=assert(f:read("*a"));f:close()
 local first=raw:match("([^\n]*)") or ""
 first=first:gsub("^\239\187\191",""):gsub("\r$","")
 if first==header then return end
 -- Only repair a headerless file if the first row looks structurally like data.
 -- Never overwrite the original without a complete backup.
 assert(first=="" or
  (csv_columns(first)==csv_columns(header) and ((header:match("^session,") and first:match("^%d%d%d%d%d%d%d%dT%d%d%d%d%d%dZ_")) or (header:match("^frame,") and first:match("^%d+,")))),
  "CSV needs manual review: "..path.." expected="..header.." actual="..first)
 local backup=path..".bak."..os.date("!%Y%m%dT%H%M%SZ")
 local n=0
 while io.open(backup,"rb") do n=n+1;backup=path..".bak."..os.date("!%Y%m%dT%H%M%SZ").."."..n end
 local b=assert(io.open(backup,"wb"))
 assert(b:write(raw));assert(b:close())
 local out=assert(io.open(path,"wb"))
 assert(out:write(header.."\n"..raw));assert(out:close())
 print("[ISSD.dribble_bot] CSV header restored path="..path.." backup="..backup)
end


local function textval(v) return v==nil and "" or tostring(v) end
function M.write(path,columns,n)
 -- Use explicit column counts: ipairs stops at the first nil value.
 local values={}
 for i=1,n do values[i]=textval(columns[i]) end
 local f=assert(io.open(path,"a"));f:write(table.concat(values,",").."\n");f:close()
end
return M
