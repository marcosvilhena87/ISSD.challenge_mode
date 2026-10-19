-- Ponto de entrada para Tools > Lua Console > Open Script (BizHawk).
-- Resolve a pasta do projeto a partir deste arquivo, inclusive se movida.
local source = debug.getinfo(1, "S").source
assert(source:sub(1, 1) == "@", "Abra este arquivo como script no Lua Console")
local lua_dir = source:sub(2):match("^(.*)[/\\][^/\\]+$")
assert(lua_dir, "Nao foi possivel identificar a pasta lua")
local root = lua_dir:gsub("[/\\]$", ""):match("^(.*)[/\\]lua$")
assert(root, "O iniciador deve estar na pasta lua/ do projeto")
_G.ISSD_PROJECT_ROOT = root:gsub("\\", "/")
print("[WRAM] Raiz: " .. _G.ISSD_PROJECT_ROOT)
local scanner = dofile(_G.ISSD_PROJECT_ROOT .. "/lua/challenge/wram_scanner.lua")
scanner.run()
