-- Iniciador do monitor de menu para BizHawk NLua.
_G.ISSD_PROJECT_ROOT = [[C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/SNES/ISSD.challenge_mode-main]]
print("[LIVE WRAM] Raiz: ".._G.ISSD_PROJECT_ROOT)
dofile(_G.ISSD_PROJECT_ROOT.."/lua/challenge/live_monitor.lua").run()
