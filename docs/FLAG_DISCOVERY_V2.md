# DRIBBLE Flag Discovery v2

A v2 isola snapshots durante o estado candidato de jogo `Game State=0` e `My Controlled Player=0x0F00`. Essa combinação **não é uma flag de presença validada**; é apenas um filtro para reduzir ruído de menu. O jogo apresenta cinco bandeiras simultâneas; as coordenadas e o contador ainda não são conhecidos.

## Execução (BizHawk)

1. Encerre todos os outros scripts Lua e execute `git pull --ff-only origin main`.
2. Carregue somente `flag_discovery_v2.lua` no Lua Console.
3. Inicie DRIBBLE LV.1. Quando o desafio começar, digite no PowerShell, na raiz do projeto:

```powershell
Add-Content .\flag_discovery_events_v2.txt 'ARM'
```

4. Jogue normalmente e tente coletar bandeiras. Não é necessário digitar durante os 30 segundos. O script captura 128 KiB a cada **60 frames emulados** (cerca de um segundo a 60 FPS), no máximo 32 snapshots. A varredura pode reduzir a velocidade real da emulação.
5. Quando o estado candidato deixar de existir, o script finaliza a análise. Também é possível interromper com `Add-Content .\flag_discovery_events_v2.txt 'STOP'`.
6. Consulte `flag_candidates_v2.csv` e `flag_timeline_v2.csv`. A linha do tempo registra a entrada, amostras da execução e a saída observada. O ranking exporta até 500 endereços e os frames de cada alteração.

```powershell
Import-Csv .\flag_candidates_v2.csv |
 Select-Object -First 30 rank,address_hex,kind,score,changes,first,last,transitions |
 Format-Table -AutoSize
```

Tipos candidatos: `counter_up` (incrementos unitários), `counter_down`, `bitmask_set` e `bitmask_clear` (um bit por amostra), `single_flag` e `stepped_other`. Capturas a cada 60 frames podem deixar passar alterações e não detectam necessariamente objetos e coordenadas. A prioridade é procurar **contadores/estados**, não identificar visualmente as cinco bandeiras. Repita com números de bandeiras coletadas diferentes e compare a direção dos contadores; `SUCCESS` e `FAILURE` devem continuar rotulados pela observação humana. Nenhuma classificação automática de vitória ou mapeamento canônico é promovida.

Teste sintético: `lua tests/test_flag_discovery_v2.lua`.
