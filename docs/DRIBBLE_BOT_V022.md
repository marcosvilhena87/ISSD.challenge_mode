# DRIBBLE Bot v0.2.2 — Waypoint Transition Fix

Corrige falso positivo de `stuck` imediatamente depois da primeira coleta, observado na v0.2.1 perto do frame 823697.

- Ao detectar decremento unitário em `WRAM 0x006B4`, em contexto de gameplay candidato, recalcula `target=6-remaining`, reinicia completamente a janela de deslocamento e ativa carência de **60 frames** para a detecção de travamento.
- `stuck` exige **15 frames de comando efetivo** durante a janela de 45 frames, deslocamento total inferior a três unidades e carência encerrada. Pulsos curtos sem comando não são contados como movimento solicitado.
- Mantém cinco waypoints, aproximação fina, recuperação da bola, busca local e limitações de tempo.
- Novo evento `flag_collected` aparece na coluna `event` do CSV, com a linha registrada obrigatoriamente no frame da coleta. `target` identifica o waypoint seguinte; esse mesmo evento representa a troca de waypoint.
- Os parâmetros são provisórios e só a execução no BizHawk poderá validar a segunda coleta; nenhum resultado de sucesso foi presumido.

## Execução

Feche outros scripts Lua, `git pull --ff-only origin main`, carregue `dribble_bot_v022.lua` no Lua Console do BizHawk e entre em DRIBBLE LV.1. Então, na raiz do projeto:

```powershell
Add-Content .\dribble_bot_commands_v022.txt 'ARM'
```

Interrompa a qualquer momento com:

```powershell
Add-Content .\dribble_bot_commands_v022.txt 'STOP'
```

Depois, consulte `dribble_bot_trace_v022.csv`:

```powershell
Import-Csv .\dribble_bot_trace_v022.csv |
 Where-Object { $_.event -eq 'flag_collected' -or $_.reason -in @('stuck','five_collected','collection_timeout') } |
 Select-Object frame,event,reason,remaining,target,player_x,player_y,buttons |
 Format-Table -AutoSize
```

Teste sintético disponível: `lua tests/test_dribble_waypoints_v022.lua`. Não substitui teste experimental no BizHawk.
