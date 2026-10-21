package.path="lua/?.lua;lua/?/init.lua;"..package.path
local P=require("challenge.controlled_player_probe")
local file="test_controlled_player_tmp.csv";os.remove(file)
local x,y=100,200
local function u16(a)
 if a==0x1ACC then return 0x0F00 end
 if a==0x1AFC then return 0x1000 end
 if a==0x00A6 then return 0x0F00 end
 return 0
end
local function s16(a)
 if a==0x0F2A then return x end
 if a==0x0F2C then return y end
 return 0
end
local p=P.new({r8=function()return 1 end,ru16=u16,rs16=s16,csv=file,session="synthetic"})
local a=p:sample(10,"PLAYING_IDLE","operator")
assert(a.my_ptr_valid and a.my_slot==11 and a.controlled_x==100 and a.possession_matches_my==1)
assert(a.cpu_ptr_valid and a.cpu_slot==1 and a.controlled_changed==0)
x=105;y=197
local b=p:sample(25,"MOVE_RIGHT","operator")
assert(b.controlled_dx==5 and b.controlled_dy==-3 and b.controlled_changed==1)
assert(b.team_possession_u16==0x0101 and b.team_possession_u8==1)
local f=assert(io.open(file,"r"));local d=f:read("*a");f:close()
assert(d:find("controlled_dx",1,true) and d:find("MOVE_RIGHT",1,true))
os.remove(file)
print("test_controlled_player_probe.lua: OK synthetic")
