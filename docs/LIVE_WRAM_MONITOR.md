# Monitor WRAM do menu Challenge Mode

## Objetivo

Identificar os bytes que representam o **desafio destacado** e o **nivel destacado**, distinguindo-os dos bytes de recordes exibidos ou valores retidos em memoria.

## Iniciar

1. Atualize o repositorio local: `git pull --ff-only origin main`.
2. Instale o projeto em `C:\\Minha_Pasta\\Jogos\\BizHawk-2.11.1-win-x64\\Lua\\SNES\\ISSD_bot\\ISSD.challenge_mode-main` (ou ajuste `ISSD_PROJECT_ROOT` em `lua/start_live_monitor.lua` para sua instalacao).
3. Confirme que a pasta `snapshots` existe; no PowerShell, use `New-Item -ItemType Directory -Force -Path "C:\\Minha_Pasta\\Jogos\\BizHawk-2.11.1-win-x64\\Lua\\SNES\\ISSD_bot\\ISSD.challenge_mode-main\\snapshots"`.
4. Abra a ROM no BizHawk e carregue **`lua/start_live_monitor.lua`** pelo Lua Console.
5. Abra o menu Challenge Mode e selecione DRIBBLE LV.1; clique em **Referencia**.
6. Mude somente DRIBBLE para PASS (sem mudar nivel), aguarde estabilizar e clique em **Mudou desafio**.
7. Mude somente LV.1 para LV.2 (sem mudar desafio), aguarde e clique em **Mudou nivel**.
8. Repita alternando desafios/níveis, inclusive em sentido inverso; gere controles com **Outra mudanca** (sair do menu, voltar, navegar em outro menu).

A captura compara toda a WRAM (131072 bytes), registra somente enderecos que mudaram e nao escreve na memoria do jogo. **O monitor nao controla o jogo.**

## Resultado

`snapshots/live_menu_changes.csv` com colunas:
`capture,label,address_hex,address_dec,before,after`.

O CSV pode conter muitos enderecos alterados por animacoes; procure enderecos que mudam **consistentemente** so quando a dimensao investigada muda. As quatro sondas anteriores (0xD708, 0xE52C, 0xD70A, 0xE52E) permanecem candidatas, nao validadas.

**Nota:** o arquivo CSV e acrescentado entre execucoes; remova ou arquive-o manualmente apenas se desejar uma coleta nova. Snapshots anteriores permanecem intactos.

Evite executar o monitor e o scanner simultaneamente. Os controles sao botoes Forms, sem disputa com atalhos do BizHawk.


## Diagnostico do caminho

O iniciador usa a raiz local definida em `ISSD_PROJECT_ROOT`. Ao iniciar, o monitor cria/verifica o CSV **antes** da primeira captura, imprimindo `[LIVE WRAM] CSV criado/verificado: ...` no Lua Console. Se nao aparecer, confira a mensagem de erro e a raiz configurada. O arquivo esperado nesta instalacao e `C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/Lua/SNES/ISSD_bot/ISSD.challenge_mode-main/snapshots/live_menu_changes.csv`. O arquivo pode conter apenas o cabecalho ate que se clique em **Referencia** e em uma comparacao posterior.
