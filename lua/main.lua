-- Entrada para o reconhecedor do Challenge Mode no BizHawk.
-- O BizHawk NLua pode nomear este chunk como [string "main"].
-- Mantenha esta raiz sincronizada com o local onde o projeto foi extraido.
_G.ISSD_PROJECT_ROOT = [[C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/SNES/ISSD.challenge_mode-main]]
dofile(_G.ISSD_PROJECT_ROOT .. "/lua/challenge/runtime.lua").run()
