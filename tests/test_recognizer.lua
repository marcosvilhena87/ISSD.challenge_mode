local catalog = dofile("lua/challenge/catalog.lua")
local rec = dofile("lua/challenge/recognizer.lua")
assert(catalog.count_scenarios() == 24)
assert(#catalog.all() == 6)
for _, item in ipairs(catalog.all()) do
  for level=1,4 do
    local r = rec.recognize({challenge=item.id, level=level, source="manual"})
    assert(r.status == "identified" and r.challenge == item.id and r.level == level)
  end
end
assert(rec.recognize(nil).status == "unknown")
assert(rec.recognize({challenge="bogus",level=1,source="manual"}).status == "unknown")
assert(rec.recognize({challenge="dribble",level=0,source="manual"}).status == "unknown")
assert(rec.recognize({challenge="dribble",level=5,source="manual"}).status == "unknown")
assert(rec.recognize({challenge="dribble",level=1,source="guess"}).status == "unknown")
assert(rec.recognize({challenge="dribble",level=1,source="validated_memory"}).status == "identified")
print("OK: 24 scenarios and negative cases")
