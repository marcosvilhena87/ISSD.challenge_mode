# DRIBBLE Timer Discovery v1 — TIME e BONUS TIME

A tela do DRIBBLE LV.1 exibe dois cronômetros. Conforme observação visual do operador, `TIME` é acionado desde o início do desafio e `BONUS TIME` é acionado após coletar as cinco bandeiras. **Nenhum endereço desses relógios foi identificado nesta etapa.** O script é uma sonda de descoberta, sem inputs e sem alterações de RAM.

## Rodar

1. Encerre os outros scripts Lua. Execute `git pull --ff-only origin main` na raiz do repositório.
2. No BizHawk, carregue **`dribble_timer_discovery.lua`**.
3. Inicie DRIBBLE LV.1 e, no PowerShell, execute `Add-Content .\dribble_timer_events_v1.txt 'ARM'`.
4. Colete as cinco bandeiras e deixe a execução continuar para observar o segundo cronômetro. A captura automática registra **128 KiB de WRAM a cada 30 frames emulados**, com limite de 75 snapshots (~37,5 s emulados). Os scans podem desacelerar a emulação.
5. Opcionalmente, anote o valor visto na tela com `Add-Content .\dribble_timer_events_v1.txt 'NOTE:TIME=00:29:63 BONUS=00:30:00'`. A nota será registrada nas capturas seguintes. Para encerrar antes, use `Add-Content .\dribble_timer_events_v1.txt 'STOP'`.
6. Envie `dribble_timer_candidates_v1.csv` e `dribble_timer_timeline_v1.csv`, com observações visuais após 5/5.

## Interpretação

- `bonus_activation_candidate`: poucas mudanças até a quinta bandeira e várias depois.
- `time_pause_candidate`: mudanças antes da quinta bandeira e quase nenhuma depois.
- `continuous_timer_candidate`: mudanças dos dois lados.
- `pre_fifth_timer_candidate`: sem quinta coleta detectada na amostragem.

A classificação é **heurística**, não prova de semântica. Bytes de animações, física, placar e outros efeitos podem apresentar as mesmas sequências. O índice da quinta coleta é inferido somente de snapshots consecutivos com `remaining=1` e `remaining=0`, ambos em estado candidato de gameplay. Se a coleta 1→0 cair entre duas amostras mas houver reset do contexto, o evento pode não ser identificado. A etapa seguinte deverá validar individualmente candidatos com leituras por frame, comparar com valores no HUD e testar a distinção de relógios.

`lua tests/test_timer_discovery.lua` executa teste sintético, não substitui BizHawk.
