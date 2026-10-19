-- Ponto de entrada BizHawk NLua para reconhecimento do Challenge Mode.
-- Ajuste a raiz caso mova o repositorio para outra pasta.
_G.ISSD_PROJECT_ROOT = [[C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/SNES/ISSD.challenge_mode-main]]
print("[ISSD.challenge_mode] Raiz: " .. _G.ISSD_PROJECT_ROOT)
local path = _G.ISSD_PROJECT_ROOT .. "/lua/challenge/runtime.lua"
local file, err = io.open(path, "rb")
assert(file, "Runtime nao encontrado em: " .. path .. " (" .. tostring(err) .. ")")
file:close()
dofile(path).run()
