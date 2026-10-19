# Reconhecedor experimental v0.4

O detector identifica **candidatos de selecao do menu**, mas **nao prova que o menu Challenge Mode esta ativo**. Nunca usar seus resultados para acionamento automatico de botoes antes de validar uma flag de modo.

| Campo | WRAM | Codificacao |
| --- | --- | --- |
| desafio A | 0xD708 | 0..5, Dribble ate Free Kick |
| desafio B | 0xE52C | par redundante do desafio |
| nivel destacado | 0x1550 | 0..3, LV1..LV4 |
| nivel legado A | 0xD70A | telemetria apenas; nao determina nivel |
| nivel legado B | 0xE52E | telemetria apenas; nao determina nivel |

O valor do desafio exige concordancia entre A e B. O nivel e lido de `0x1550` e deve estar entre 0 e 3. O runtime aguarda tres frames consistentes e imprime `candidate`, nunca `identified` com base so na WRAM.

Para testar, execute `lua/main.lua` no Lua Console e alterne DRIBBLE LV1 -> LV2 -> LV3 -> LV4, depois alterne modalidade. Saia do menu: um candidato persistente fora do menu **nao e reconhecimento valido**, e sim memoria residual. Registre controles negativos com o Live Monitor.

Testes: `lua tests/test_memory_probe.lua`, `lua tests/test_recognizer.lua`.

## v0.5 — transições e diagnóstico

Ao carregar `lua/main.lua`, o runtime cria ou acrescenta linhas em `snapshots/recognizer_transitions_v05.csv`. Cada mudança de classificação inclui número sequencial de frame, estado, último candidato e valores brutos de `0xD708`, `0xE52C`, `0x1550`, `0xD70A` e `0xE52E`. Alterações inválidas são identificadas como `invalid_transition`.

Durante a estabilização de três leituras, o último candidato é mantido apenas internamente como `pending` (não confirmado), evitando spam `unknown/stabilizing` no console. O próximo candidato estável é publicado quando confirmado. **Nenhum byte de presença de menu foi validado.** A v0.5 não deve ser usada para pressionar botões automaticamente.

Para coletar evidências, navegue entre os seis desafios e seus níveis, depois saia para a tela Training/Challenge e volte. Envie o CSV de transições juntamente com a descrição de quais telas estavam abertas. O CSV não é uma prova independente de presença do menu.
