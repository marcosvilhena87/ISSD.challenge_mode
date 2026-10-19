local analyzer=dofile("lua/challenge/wram_analyzer.lua")
local folder=arg and arg[1] or "snapshots"
local samples,nbytes=analyzer.load(folder)
local found=analyzer.analyze(samples,nbytes)
local f=assert(io.open(folder.."/candidates.csv","wb"))
f:write("address_hex,address_dec,width_bytes,dimension,distinct_values,status\n")
for _,c in ipairs(found) do
 f:write(string.format("0x%05X,%d,%d,%s,%d,candidate\n",c.offset,c.offset,c.width,c.dimension,c.distinct))
end
f:close()
print(string.format("Analisados %d cenarios x %d bytes; %d candidatos em %s/candidates.csv",#samples,nbytes,#found,folder))
print("ATENCAO: candidatos correlacionados nao sao enderecos validados.")
