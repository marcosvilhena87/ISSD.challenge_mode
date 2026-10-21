# DRIBBLE Bot v0.2.1 — Precision Approach

Implementação experimental para corrigir a parada prematura em (547,265), ocorrida com o waypoint (555,261). A v0.2 continua preservada, e esta versão cria novos comandos e CSV.

## Estratégia
- Usa a mesma rota manual aproximada: (555,261), (772,304), (974,356), (1228,293), (1450,367).
- Confirma coleta somente quando `WRAM 0x006B4` diminui durante `GS=0` e `PTR=0x0F00`.
- Ao aproximar-se, reduz a tolerância de movimento para **2 unidades** e envia pulsos curtos (um em cada quatro frames), em vez de simplesmente parar dentro de 10/9 unidades.
- Após 45 frames dentro da região inicial de ±12, executa uma pequena busca espacial de offsets até 8 unidades, retornando ao ponto original.
- Desarma após 240 frames sem coleta desde a entrada na região próxima, na ausência de movimento, em contadores descontínuos, perda de contexto ou limite de 1800 frames.
- Se a bola estiver afastada e a posse não corresponder ao jogador, tenta recuperá-la. Posse e coordenadas permanecem hipóteses operacionais.
- Não procura as coordenadas reais da bandeira na WRAM, não modifica RAM e não afirma que detecta SUCCESS visual.

## Executar
1. Feche os outros scripts que enviam inputs ao BizHawk e rode `git pull --ff-only origin main`.
2. Carregue **`dribble_bot_v021.lua`** no Lua Console. Inicia desarmado.
3. Após entrar visualmente em DRIBBLE LV.1, no PowerShell, na raiz:

```powershell
Add-Content .\dribble_bot_commands_v021.txt 'ARM'
```

4. Para interromper manualmente:

```powershell
Add-Content .\dribble_bot_commands_v021.txt 'STOP'
```

5. Após a tentativa, salve `dribble_bot_trace_v021.csv` e informe as bandeiras coletadas.

```powershell
Import-Csv .\dribble_bot_trace_v021.csv |
 Group-Object reason |
 Select-Object Name,Count |
 Format-Table -AutoSize

Import-Csv .\dribble_bot_trace_v021.csv |
 Where-Object { $_.reason -in @('collection_timeout','not_playing','five_collected','stuck','counter_discontinuity','local_search') } |
 Select-Object -Last 40 frame,reason,remaining,target,player_x,player_y,ball_x,ball_y,buttons |
 Format-Table -AutoSize
```

Os pulsos e offsets são hipóteses de calibração: é possível ocorrer oscilação, passagem pela bandeira ou parada por timeout. A política é testada sinteticamente por `lua tests/test_dribble_waypoints_v021.lua`. É necessário testar no BizHawk para validar coleta automática.
