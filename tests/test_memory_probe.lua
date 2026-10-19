local probe=dofile("lua/challenge/memory_probe.lua")
local ids={"dribble","pass","shoot","defense","corner_kick","free_kick"}
for n,id in ipairs(ids) do
  for lv=0,3 do
    local v={challenge_a=n-1,challenge_b=n-1,selected_level=lv,
             legacy_level_a=3,legacy_level_b=3}
    local r=probe.decode(v)
    assert(r.status=="candidate" and r.challenge==id and r.level==lv+1)
    local values={[0xD708]=n-1,[0xE52C]=n-1,[0x1550]=lv,
                  [0xD70A]=3,[0xE52E]=3}
    local x=probe.read(function(a) return values[a] end)
    assert(x.challenge==id and x.level==lv+1)
  end
end
assert(probe.decode({challenge_a=0,challenge_b=1,selected_level=0}).reason=="challenge_pair_mismatch")
assert(probe.decode({challenge_a=6,challenge_b=6,selected_level=0}).reason=="out_of_range")
assert(probe.decode({challenge_a=0,challenge_b=0,selected_level=4}).reason=="out_of_range")
assert(probe.decode({challenge_a=0,challenge_b=0}).reason=="read_failed")
assert(probe.read(function() error("unavailable") end).status=="unknown")
print("OK: v0.4, 24 combinations, stale legacy levels, invalid values")
