package.path="lua/?.lua;lua/?/init.lua;"..package.path
local M=require("challenge.flag_counter_validation")
local path="test_flag_counter_validation_tmp.csv";os.remove(path)
local remaining=5
local m=M.new({csv=path,session="synthetic",u8=function(a) if a==0x006B4 then return remaining else return 1 end end,u16=function(a) if a==0x00BA then return 0 elseif a==0x1ACC then return 0x0F00 else return 0 end end,s16=function()return 0 end})
local a=m:sample(10,"initial","PLAYING");assert(a.remaining_06b4==5 and a.delta_06b4==nil)
local b=m:sample(11,"frame","NO_COLLECTION");assert(b.delta_06b4==0)
remaining=4
local c=m:sample(12,"frame","FLAG_COLLECTED");assert(c.delta_06b4==-1 and c.candidate_phase=="playing_candidate")
remaining=5
local d=m:sample(13,"frame","START_MENU");assert(d.delta_06b4==1)
local f=assert(io.open(path,"r"));local data=f:read("*a");f:close()
assert(data:find("delta_06b4",1,true) and data:find("FLAG_COLLECTED",1,true))
os.remove(path)
print("test_flag_counter_validation.lua: OK (synthetic only)")
