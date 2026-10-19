local probe=dofile("lua/challenge/memory_probe.lua")
local ids={"dribble","pass","shoot","defense","corner_kick","free_kick"}
for n,id in ipairs(ids) do
  for lv=0,3 do
    local v={challenge_a=n-1,challenge_b=n-1,level_a=lv,level_b=lv}
    local r=probe.decode(v)
    assert(r.status=="candidate" and r.challenge==id and r.level==lv+1)
    local values={[0xD708]=n-1,[0xE52C]=n-1,[0xD70A]=lv,[0xE52E]=lv}
    local x=probe.read(function(a) return values[a] end)
    assert(x.challenge==id and x.level==lv+1)
  end
end
assert(probe.decode({challenge_a=0,challenge_b=1,level_a=0,level_b=0}).status=="unknown")
assert(probe.decode({challenge_a=0,challenge_b=0,level_a=0,level_b=1}).status=="unknown")
assert(probe.decode({challenge_a=6,challenge_b=6,level_a=0,level_b=0}).status=="unknown")
assert(probe.decode({challenge_a=0,challenge_b=0,level_a=4,level_b=4}).status=="unknown")
assert(probe.read(function() error("unavailable") end).status=="unknown")
print("OK: 24 candidate pairs, mismatch, range and read failure tests")
