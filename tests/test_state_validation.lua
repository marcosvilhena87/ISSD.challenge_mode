package.path="lua/?.lua;lua/?/init.lua;"..package.path
local M=require("challenge.state_validation")
assert(M.classify({game_state=0,my_controlled_player=0x0F00})=="possible_playing")
assert(M.classify({game_state=5,my_controlled_player=0x0F00})=="possible_transition")
assert(M.classify({game_state=6,my_controlled_player=0x0F00})=="possible_transition")
assert(M.classify({game_state=6,my_controlled_player=0})=="possible_post_game_or_menu")
assert(M.classify({game_state=0,my_controlled_player=0})=="unknown")
local path="test_state_validation_tmp.csv";os.remove(path)
local gs=0;local ptr=0x0F00
local p=M.new({csv=path,session="synthetic",r8=function()return 1 end,rs16=function()return 0 end,ru16=function(a) if a==0x00BA then return gs elseif a==0x1ACC then return ptr else return 0 end end})
local a=p:sample(10,"initial","UNKNOWN");assert(a.candidate_state=="possible_playing")
gs=6
local b=p:sample(15,"periodic","UNKNOWN");assert(b.state_changed==1 and b.candidate_state=="possible_transition")
ptr=0
local c=p:sample(20,"operator","FAILURE");assert(c.pointer_changed==1 and c.candidate_state=="possible_post_game_or_menu")
local f=assert(io.open(path,"r"));local d=f:read("*a");f:close()
assert(d:find("FAILURE",1,true) and d:find("possible_post_game_or_menu",1,true))
os.remove(path);print("test_state_validation.lua OK (synthetic)")
