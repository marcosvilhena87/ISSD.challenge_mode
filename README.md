# ISSD Challenge Mode (SNES)

Projeto independente de reconhecimento, instrumentação e futura automação do **Challenge Mode** de International Superstar Soccer Deluxe, utilizando **BizHawk + Lua**.

## Estado

- Catálogo inicial: 6 modalidades x 4 níveis = 24 cenários.
- Reconhecimento v0.1: por metadados explícitos de sessão (sem endereços WRAM inventados).
- Detecção de seleção por pixels, OCR ou memória: **não implementada**; requer calibração empírica.
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

Abra uma ROM legalmente obtida de ISSD no BizHawk (núcleo SNES com Lua habilitado). Em **Tools > Lua Console**, carregue `lua/main.lua` a partir da raiz do repositório. O script exibe estado "unknown" até haver evidência configurada.

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
