package.path="lua/?.lua;lua/?/init.lua;"..package.path
local D=require("challenge.flag_discovery_v2")
local snapshots={}
for i=1,4 do local s={};for j=1,D.SIZE do s[j]=0 end;s[0x120+1]=i-1;s[0x130+1]=2^(i-1)-1;s[0x140+1]=i==4 and 1 or 0;snapshots[i]=s end
local results,total=D.analyze(snapshots,{10,70,130,190},20)
assert(total>=3)
local byaddr={};for _,v in ipairs(results) do byaddr[v.address]=v end
assert(byaddr[0x120] and byaddr[0x120].kind=="counter_up")
assert(byaddr[0x130] and byaddr[0x130].kind=="bitmask_set")
assert(byaddr[0x140] and byaddr[0x140].kind=="single_flag")
local file="test_flag_v2_tmp.csv";os.remove(file)
D.write(file,"synthetic",results,total)
local f=assert(io.open(file,"r"));local data=f:read("*a");f:close()
assert(data:find("10:",1,true)==nil) -- transitions start at second capture
assert(data:find("70:0>1",1,true))
os.remove(file)
print("test_flag_discovery_v2.lua OK (synthetic)")
