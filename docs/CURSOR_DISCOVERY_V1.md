# WRAM Cursor Discovery v1

Scanner de leitura apenas (BizHawk 2.11.1, Lua/NLua). Nao envia comandos, nao altera a memoria do jogo e **nao valida enderecos automaticamente**. Analisa a faixa WRAM 0x00000..0x1FFFF (128 KiB), lendo u8. Pode causar pausa perceptivel durante cada captura.

## Uso

1. Pare `main.lua` no console Lua. Atualize o projeto e carregue `cursor_discovery.lua` da **raiz** no BizHawk. Nao execute os dois scripts simultaneamente.
2. Abra DRIBBLE LV.1 e a tela com as opcoes CHALLENGE START, KEY CONFIGURATION e CHANGE CONTROLLER.
3. Deixe CHALLENGE START destacado e, no PowerShell na raiz do repositorio, execute `Add-Content .\\cursor_capture_events_v1.txt 'A'`.
4. Mova para KEY CONFIGURATION e execute `Add-Content .\\cursor_capture_events_v1.txt 'B'`.
5. Mova para CHANGE CONTROLLER e execute `Add-Content .\\cursor_capture_events_v1.txt 'C'`.
6. Retorne a CHALLENGE START e execute `Add-Content .\\cursor_capture_events_v1.txt 'A'`.
7. Espere a mensagem `matched=N` antes de consultar `cursor_candidates_v1.csv`. O script para depois da quarta captura. Verifique a tela visual em cada etapa; o evento e lido quando o script o encontra, nao necessariamente no frame exato da tecla.

O scanner ignora eventos antigos existentes antes da inicializacao e recusa eventos fora da ordem esperada; nao use as letras em outras telas. Execute outra sessao independente com novo carregamento do script para testar reproducibilidade.

## Interpretacao

A comparacao so lista offsets onde `A1 == A2`, `A != B`, `A != C` e `B != C`. Resultados ordenados com preferencia (mas **nao validade**) ao padrao ascendente A,A+1,A+2. Outras codificacoes sao preservadas. A ausencia de resultados nao significa que a selecao nao exista em WRAM: pode ser representacao multibyte, estado transitório, leitura nao atomica ou endereco fora da faixa sondada. O CSV inclui valores e frames, nao dumps completos.

**Amostragem:** uma captura por estado; nao ha controle automatico de estabilidade temporal. Sao necessarias repeticoes, controles negativos e avaliacao visual antes de sugerir endereco para `ISSD.mapping`. O projeto nao altera o catalogo canônico nesta fase.

Arquivos de saida: `cursor_capture_events_v1.txt` e `cursor_candidates_v1.csv` na raiz. Nao comitar dados de jogo. Teste sintetico: `lua tests/test_cursor_discovery.lua`.
