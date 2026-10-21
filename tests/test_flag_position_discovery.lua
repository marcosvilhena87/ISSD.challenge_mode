package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.flag_position_discovery")
local path="test_flag_positions_tmp.csv";os.remove(path)
local count=5
local m=P.new({session="synthetic",path=path,read8=function(a) if a==0x006B4 then return count end return 0 end,read16=function(a) if a==0x00BA then return 0 end if a==0x1ACC then return 0x0F00 end return 0 end,reads16=function(a) if a==0x0F2A then return 547 end return 270 end})
local a=m:step(1);assert(a.event=="entered_gameplay")
local b=m:step(2);assert(b.event=="frame")
count=4
local c=m:step(3);assert(c.event=="collection_candidate" and c.collection_index==1 and c.remaining_before==5)
local d=m:step(4);assert(d.event=="frame")
local f=assert(io.open(path));local s=f:read("*a");f:close()
assert(s:find("collection_candidate",1,true) and s:find("547",1,true))
os.remove(path)
print("test_flag_position_discovery.lua OK synthetic")
