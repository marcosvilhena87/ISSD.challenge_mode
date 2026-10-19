# Iniciar o scanner WRAM no BizHawk 2.11.1

## Importante: erro NLua `[string "main"]:4`

O BizHawk pode identificar o script carregado como `[string "main"]`; portanto, **não use** `debug.getinfo(1, "S").source` para descobrir o caminho do arquivo. O iniciador `lua/start_scanner.lua` usa uma raiz explícita, apontando para a instalação informada:

`C:/Minha_Pasta/Jogos/BizHawk-2.11.1-win-x64/SNES/ISSD.challenge_mode-main`

## Executar

1. Atualize a pasta local com `git pull` ou baixe o ZIP mais recente e substitua os arquivos antigos (preserve a pasta `snapshots`).
2. Abra a ROM de International Superstar Soccer Deluxe no BizHawk.
3. Em **Tools > Lua Console > Open Script**, selecione **`lua/start_scanner.lua`**, não `lua/challenge/wram_scanner.lua`.
4. Confirme no console `[WRAM] Raiz: ...` e as instruções de F6/F7.
5. Veja `[WRAM] Sessao: .../snapshots/session_AAAAMMDD_HHMMSS`. Fora do desafio, pressione **F7** para o baseline; em seguida, pressione **F6** para os 48 cenários na ordem de `docs/WRAM_SCANNER.md`.

Se ainda surgir a mensagem `Abra este arquivo como script no Lua Console`, a **versão local é antiga**: abra `lua/start_scanner.lua`, remova todas as linhas com `local source = debug.getinfo`, `assert(source:sub`, `lua_dir` e `local root =`, ou substitua o arquivo integralmente pela versão da branch main.

## Diagnóstico

- Se a pasta foi movida, ajuste somente `_G.ISSD_PROJECT_ROOT` dentro de `lua/start_scanner.lua`.
- Verifique que `snapshots/` existe e permite gravação.
- O scanner cria uma pasta nova a cada execução. Não é necessário excluir ou mover o `manifest.csv` anterior.
- Em erros novos, copie a exceção completa da saída do Lua Console.
- O scanner registra dados; não reconhece modalidade e nível automaticamente nem controla jogadores.
