package.path="lua/?.lua;lua/?/init.lua;"..package.path
local D=require("challenge.timer_decoder_v1")
assert(D.bcd(0x29)==29)
assert(D.bcd(0x30)==30)
assert(D.bcd(0x19)==19)
assert(D.bcd(0x2A)==nil)
assert(D.bcd(-1)==nil)
local function sample(frame,phase,t,b,frac_t,frac_b)
 return {frame=frame,phase=phase,b_014F0=t,b_014F1=0,b_014F2=frac_t%256,b_014F3=math.floor(frac_t/256),b_014F4=b,b_014F5=0,b_014F6=frac_b%256,b_014F7=math.floor(frac_b/256)}
end
local rows={sample(1,"time_candidate",0x29,0x30,65000,0),sample(2,"time_candidate",0x29,0x30,64000,0),sample(3,"time_candidate",0x28,0x30,63000,0),sample(4,"bonus_candidate",0x28,0x30,63000,65500),sample(5,"bonus_candidate",0x28,0x30,63000,64500),sample(6,"bonus_candidate",0x28,0x29,63000,63500)}
local z=D.decode(rows[1]);assert(z.time_seconds==29 and z.bonus_seconds==30 and z.time_fraction_u16==65000)
local a=D.summarize(rows)
assert(a.time_candidate.samples==3 and a.time_candidate.seconds_transitions==1)
assert(a.bonus_candidate.samples==3 and a.bonus_candidate.seconds_transitions==1)
assert(a.time_candidate.fraction_transitions==2 and a.bonus_candidate.fraction_transitions==2)
print("test_timer_decoder_v1.lua OK synthetic")
