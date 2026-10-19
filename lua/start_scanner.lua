-- BizHawk NLua costuma identificar o script como [string "main"].
-- Portanto, nao inferir o diretorio com debug.getinfo().
-- Ajuste este caminho apenas se mover a pasta do projeto.
_G.ISSD_PROJECT_ROOT = [[C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/SNES/ISSD.challenge_mode-main]]
print("[WRAM] Raiz: " .. _G.ISSD_PROJECT_ROOT)
local scanner = dofile(_G.ISSD_PROJECT_ROOT .. "/lua/challenge/wram_scanner.lua")
assert(type(scanner) == "table" and type(scanner.run) == "function", "Scanner nao retornou .run()")
scanner.run()
