package.path="lua/?.lua;lua/?/init.lua;"..package.path
local v=require("challenge.cursor_validation")
assert(v.address==0x1542)
assert(v.valid_label("A") and v.valid_label("PLAYING"))
assert(not v.valid_label("INVALID"))
local values={0,2,1,0,0,1}
local current=1
local file="test_cursor_validation_v2_tmp.csv"
os.remove(file)
local m=v.new({read=function(addr,domain)
 assert(addr==0x1542 and domain=="WRAM")
 return values[current]
end,csv=file,session="synthetic"})
local _,value,match=m:sample(1,"operator","A")
assert(value==0 and match=="yes")
current=2
_,value,match=m:sample(2,"operator","C")
assert(value==2 and match=="yes")
current=3
_,value,match=m:sample(3,"operator","B")
assert(value==1 and match=="yes")
current=4
_,value,match=m:sample(4,"operator","A")
assert(value==0 and match=="yes")
assert(not m:sample(5,"transition","A"))
current=5
_,value,match=m:sample(6,"operator","PLAYING")
assert(value==0 and match=="not_applicable")
current=6
assert(m:sample(7,"transition","PLAYING"))
local f=assert(io.open(file,"r"));local data=f:read("*a");f:close()
assert(data:find("negative_control_uninterpreted",1,true))
assert(data:find("hypothesis_only",1,true))
assert(not data:find("confirmed",1,true))
os.remove(file)
print("test_cursor_validation.lua: OK (synthetic only)")
