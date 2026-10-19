# Iniciar o scanner WRAM no BizHawk

## Pelo Lua Console (recomendado)

1. Atualize o repositório local com `git pull` ou baixe o ZIP atualizado.
2. Abra a ROM de International Superstar Soccer Deluxe no BizHawk.
3. Em **Tools > Lua Console > Open Script**, selecione **`lua/start_scanner.lua`** — **não** selecione diretamente `lua/challenge/wram_scanner.lua`.
4. A janela de saída deve imprimir `[WRAM] Raiz: ...` e `[WRAM] Inicie FORA do desafio...`.
5. Na tela fora do desafio, pressione F7 para o baseline; depois F6 para cada um dos 48 casos na ordem documentada em `WRAM_SCANNER.md`.

O iniciador descobre a raiz com base na localização do próprio arquivo. Funciona mesmo quando o projeto está dentro de uma subpasta `SNES`.

## Alternativa para Lua Console: execução de expressão

Se o console permitir comandos Lua interativos, rode a partir da raiz correta (ajuste o caminho):

```lua
_G.ISSD_PROJECT_ROOT = [[C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/SNES/ISSD.challenge_mode-main]]
dofile(_G.ISSD_PROJECT_ROOT .. "/lua/challenge/wram_scanner.lua").run()
```

## Se fechar ou mostrar erro

- Verifique se `snapshots/` existe no diretório do projeto e permite gravação.
- Se `snapshots/manifest.csv` já existir, **não o apague sem salvar os dados**; arquive a coleta anterior antes de recomeçar.
- Observe as mensagens e exceções na saída do Lua Console.
- Confirme que a ROM SNES está carregada e que o domínio `WRAM` existe com ao menos 128 KiB.
- A coleta é manual; não detecta desafio ou nível automaticamente.
