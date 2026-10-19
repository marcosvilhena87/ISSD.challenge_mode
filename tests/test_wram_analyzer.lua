local analyzer=dofile("lua/challenge/wram_analyzer.lua")
local ids={"dribble","pass","shoot","defense","corner_kick","free_kick"}
local samples={}
for round=1,2 do
 for ci,id in ipairs(ids) do
  for lv=1,4 do
   -- offset 0 = ID, offset 1 = level; offset 2 varia na segunda rodada
   local raw=string.char(ci,lv,round,0,ci*10+lv)
   samples[#samples+1]={challenge=id,level=lv,round=round,raw=raw}
  end
 end
end
local result=analyzer.analyze(samples,5)
local found={}
for _,c in ipairs(result) do
 found[c.offset..":"..c.width..":"..c.dimension]=true
end
assert(found["0:1:challenge"],"ID nao encontrado")
assert(found["1:1:level"],"nivel nao encontrado")
assert(not found["2:1:challenge"] and not found["2:1:level"],"variacao entre rodadas nao filtrada")
local bad={}
for i,s in ipairs(samples) do if i<48 then bad[#bad+1]=s end end
assert(not pcall(function() analyzer.analyze(bad,5) end),"ausencia de amostra nao detectada")
print("OK: identificacao ID/level, ruído entre rodadas e dados incompletos")
