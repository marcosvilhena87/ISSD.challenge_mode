package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.gameplay_probe")
local path="test_gameplay_probe_tmp.csv"
os.remove(path)
local shift=0
local s=P.new({csv=path,session="synthetic",read8=function(addr,domain)
 assert(domain=="WRAM");if addr==0x0006 then return 1 end;return 0
end,read16u=function(addr,domain) assert(domain=="WRAM");return 0 end,
read16s=function(addr,domain)
 assert(domain=="WRAM")
 return math.floor(addr/2)+shift
end})
local a=s:snapshot(10,"START_MENU","operator",30)
assert(a.ball_x==0x042A/2 and a.valid_positions==23 and a.total_moved==0 and a.error_count==0)
shift=5
local b=s:snapshot(40,"PLAYING_MOVING","periodic",30)
assert(b.ball_moved==1 and b.my_moved==11 and b.cpu_moved==11 and b.total_moved==22)
assert(#P.columns==17+44)
local f=assert(io.open(path,"r"));local c=f:read("*a");f:close()
assert(c:find("my_p11_x",1,true) and c:find("cpu_p11_y",1,true))
assert(c:find("PLAYING_MOVING",1,true))
os.remove(path)
print("test_gameplay_probe.lua: OK (synthetic only)")
