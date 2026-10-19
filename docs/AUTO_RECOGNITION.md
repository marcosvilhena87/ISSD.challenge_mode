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
