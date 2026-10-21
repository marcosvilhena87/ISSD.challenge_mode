package.path="lua/?.lua;lua/?/init.lua;"..package.path
local M=require("challenge.dribble_focused_probe")
local path="test_dribble_focused_tmp.csv";os.remove(path)
local dx=0
local function rs(addr)
 if addr==0x042A then return 100+dx end
 if addr==0x042C then return 200 end
 if addr==0x0F2A then return 90+dx end
 if addr==0x0F2C then return 200 end
 return 0
end
local p=M.new({session="test",csv=path,r8=function()return 1 end,ru16=function(addr) if addr==0x042A then return 100+dx end return 0 end,rs16=rs})
local a=p:sample(100,"initial")
assert(a.distance_sq==100 and a.ball_changed==0 and a.player_changed==0)
dx=5
local b=p:sample(105,"periodic")
assert(b.ball_dx==5 and b.player_dx==5 and b.distance_sq==100 and b.elapsed_frames==5)
local f=assert(io.open(path,"r"));local data=f:read("*a");f:close();assert(data:find("player11_x",1,true));os.remove(path)
print("test_dribble_focused_probe.lua: OK (synthetic only)")
