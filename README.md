# ISSD Challenge Mode (SNES)

Projeto independente de reconhecimento, instrumentação e futura automação do **Challenge Mode** de International Superstar Soccer Deluxe, utilizando **BizHawk + Lua**.

## Estado

- Catálogo inicial: 6 modalidades x 4 níveis = 24 cenários.
- Reconhecimento experimental v0.4: desafio em 0xD708/0xE52C, nivel destacado em 0x1550. Os antigos 0xD70A/0xE52E permanecem apenas como sondas auxiliares. Resultado `candidate`, sem validacao de presenca do menu.
- Leitura de memória implementada como hipótese. Detecção comprovada do modo ainda requer controles negativos em menus e partidas normais.
- Botões de controle: **não acionados** nesta etapa.

## Estrutura

- `data/challenges.lua`: catálogo e recordes observados nas capturas.
- `lua/main.lua`: ponto de entrada BizHawk.
- `lua/challenge/catalog.lua`: interface de catálogo e validação.
- `lua/challenge/recognizer.lua`: reconhecedor por observações explícitas e contexto confirmado.
- `lua/challenge/runtime.lua`: adaptador BizHawk e relatório de mudanças.
- `tests/test_recognizer.lua`: testes sem BizHawk.
- `docs/memory-discovery.md`: protocolo de investigação.

## Execução no BizHawk

Pasta local: `C:\Minha_Pasta\Jogos\BizHawk-2.11.1-win-x64\ISSD.challenge_mode-main`.

Abra a ROM no BizHawk 2.11.1. Em **Tools > Lua Console**, carregue `C:\Minha_Pasta\Jogos\BizHawk-2.11.1-win-x64\ISSD.challenge_mode-main\lua\main.lua`. O script usa o caminho absoluto, sem depender do diretório atual do Lua Console. O script exibe estado "unknown" até haver evidência configurada.

Para teste manual, antes de carregar o script configure no Lua Console:
```lua
ISSD_CHALLENGE_OBSERVATION = { challenge = "dribble", level = 1, source = "manual" }
```
Essa variável descreve uma **observação manual**, não comprova identificação automática pela RAM.

Execute testes com `lua tests/test_recognizer.lua` (Lua 5.1+).

## Critérios para reconhecimento automático futuro

Qualquer endereço ou assinatura deve ser registrado com domínio de memória, largura, endianidade, evidência em múltiplos desafios/níveis, validação negativa fora do modo e ROM/build. Não reutilizar endereços do ISSD_bot sem prova.

## Créditos dos dados

Descrições e recordes foram transcritos das seis capturas fornecidas pelo usuário em 19/10/2026. Formato do cronômetro e significado exato de pontuação permanecem a validar.

## Scanner de WRAM (v0.2)

Abra **`lua/start_scanner.lua`** pelo **Tools > Lua Console > Open Script** do BizHawk. Não abra diretamente `lua/challenge/wram_scanner.lua` — esse arquivo é um módulo e não chama `.run()` sozinho.

**Erro NLua `[string "main"]:4: Abra este arquivo como script no Lua Console`?** Sua cópia local do iniciador é antiga. Atualize-a com a versão da branch `main`, que não usa `debug.getinfo()` e tem o caminho da pasta `SNES` configurado.

Guia detalhado: [docs/START_SCANNER.md](docs/START_SCANNER.md). Protocolo de coleta e análise: [docs/WRAM_SCANNER.md](docs/WRAM_SCANNER.md).

- Fora dos desafios: pressione K uma vez (baseline).
- Para cada um dos 24 cenários, pressione O; repita em duas rodadas.
- Em Lua local: `lua tests/test_wram_analyzer.lua` e `lua lua/analyze_snapshots.lua`.
- Cada execução cria `snapshots/session_AAAAMMDD_HHMMSS/` com `manifest.csv` e arquivos `.hex`; não é mais necessário excluir `snapshots/manifest.csv`.\n- Para analisar uma coleta: `lua lua/analyze_snapshots.lua "snapshots/session_AAAAMMDD_HHMMSS"`. O `candidates.csv` é salvo na própria sessão. Os offsets são hipóteses.

O scanner não reconhece automaticamente o menu. Não envie ROM ou snapshots para o Git.


> **Teclas do scanner:** `K` captura o baseline e `O` captura o proximo cenario. As teclas F1-F10 sao reservadas para atalhos de savestate no BizHawk. Caso K/O estejam mapeadas no seu emulador, altere `BASELINE_KEY` e `CAPTURE_KEY` em `lua/challenge/wram_scanner.lua` e revise os atalhos do BizHawk.

## Reconhecimento por WRAM (experimental)

Execute `lua/main.lua` no Lua Console para observar mudanças de desafio/nível. Leia [docs/AUTO_RECOGNITION.md](docs/AUTO_RECOGNITION.md) para endereços, interpretação, limitações e testes. O scanner continua independente em `lua/start_scanner.lua`.

## Monitor WRAM ao vivo (menu)

Para investigar falso positivo (exemplo: menu em DRIBBLE LV.1 mas sonda reporta FREE KICK LV.4), abra `lua/start_live_monitor.lua` no Lua Console. A janela permite capturar uma referencia e comparar as mudancas apos alternar **somente** o desafio ou o nivel. O CSV sera criado na inicializacao em `snapshots/live_menu_changes.csv` (dentro da raiz configurada em `lua/start_live_monitor.lua`). Confirme a existencia da pasta `snapshots` e consulte a mensagem de caminho no Lua Console. Guia: [docs/LIVE_WRAM_MONITOR.md](docs/LIVE_WRAM_MONITOR.md).

### Mudanca v0.4

O nivel selecionado no menu vem de `WRAM 0x1550` (0..3), e nao mais dos enderecos legados `0xD70A/0xE52E`. A leitura de desafio usa a concordancia `0xD708 == 0xE52C` (0..5). Sem uma flag comprovada de presenca do menu, o status continua `candidate` mesmo fora dele.
