-- WRAM Cursor Validation v2: verificacao de candidato, nunca confirmacao automatica.
local M={}
M.address=0x1542
local expected={A=0,B=1,C=2}
local allowed={A=true,B=true,C=true,MAIN_MENU=true,MODE_SELECTION=true,INPUT_NAME=true,CHALLENGE_SELECTION=true,LEVEL_SELECT=true,PLAYING=true,PAUSE=true,OTHER=true}
function M.new(opts)
 assert(opts and opts.read and opts.csv and opts.session,"missing opts")
 local self=setmetatable({read=opts.read,csv=opts.csv,session=opts.session,last=nil},{__index=M})
 local f=assert(io.open(self.csv,"a+"))
 if f:seek("end")==0 then f:write("session,frame,kind,label,address_hex,value,expected,match,assessment\n") end
 f:close()
 return self
end
function M:sample(frame,kind,label)
 local ok,value=pcall(self.read,M.address,"WRAM")
 if not ok or type(value)~="number" then error("WRAM read failure at 0x01542") end
 if kind=="transition" and value==self.last then return false end
 self.last=value
 local exp=expected[label]
 local match= exp==nil and "not_applicable" or (value==exp and "yes" or "no")
 local assessment=(exp==nil) and "negative_control_uninterpreted" or "hypothesis_only"
 local f=assert(io.open(self.csv,"a"))
 f:write(string.format("%s,%d,%s,%s,0x01542,%d,%s,%s,%s\n",
 self.session,frame,kind,label or "",value,exp and tostring(exp) or "",match,assessment))
 f:flush();f:close()
 return true,value,match
end
function M.valid_label(label) return allowed[label]==true end
return M
