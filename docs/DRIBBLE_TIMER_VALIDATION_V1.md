# DRIBBLE Timer Validation v1

Experimento somente de leitura: coleta a cada frame os oito bytes candidatos `WRAM 0x014F0..0x014F7` e suas interpretações little-endian u16/u32. Nenhum deles foi validado como TIME ou BONUS TIME. Registra GS, ponteiro de jogador, `0x006B4` e marca a fase com base no contador de bandeiras. Logs são anexados por sessão no CSV.

## BizHawk / PowerShell

1. Encerre os outros scripts Lua e rode `git pull --ff-only origin main`.
2. Abra `dribble_timer_validation_v1.lua` no Lua Console; a execução começa desarmada.
3. Entre em DRIBBLE LV.1 e execute `Add-Content .\dribble_timer_validation_events_v1.txt 'ARM'`.
4. Colete cinco bandeiras, deixe o jogo transicionar e/ou execute `Add-Content .\dribble_timer_validation_events_v1.txt 'STOP'`.
5. Anote valores efetivamente visíveis, se possível em instantes separados:
   `Add-Content .\dribble_timer_validation_events_v1.txt 'NOTE:TIME=00:19:00 BONUS=00:30:00'`.
   A nota é anexada a um frame de observação, que pode não coincidir exatamente com o instante em que o operador enxergou o HUD.
6. Envie `dribble_timer_validation_v1.csv` para validação de sequência e formato.

## Colunas
- `b_014F0..b_014F7`: valores u8 dos oito bytes.
- `w_014F0,w_014F2,w_014F4,w_014F6`: u16 little-endian em offsets pares.
- `d_014F0,d_014F4`: u32 little-endian dos dois blocos.
- `phase`: `time_candidate` (GS=0, PTR=0x0F00, remaining=1..5), `bonus_candidate` (mesmo contexto, remaining=0) e `outside_gameplay`; sem assumir semântica dos relógios.
- `event`: primeira amostra, transição de fase, decremento de bandeira ou amostra comum.

O script termina automaticamente ao sair do gameplay após ter observado uma fase válida, ou após 2400 frames gravados. Pode causar desaceleração por I/O a cada frame. Não executa ações de controle do jogo e não escreve na WRAM.
