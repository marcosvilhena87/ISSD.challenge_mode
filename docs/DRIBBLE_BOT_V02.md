# DRIBBLE Bot v0.2 — Waypoint Navigation

Controle experimental para **coletar as cinco bandeiras** de DRIBBLE LV.1. Usa como **waypoints aproximados** as coordenadas do jogador nos frames de decremento do contador obtidas na sessão manual `20261021T231339Z`:

| Alvo | Player X | Player Y | Coleta esperada |
|---|---:|---:|---|
| 1 | 555 | 261 | 5→4 |
| 2 | 772 | 304 | 4→3 |
| 3 | 974 | 356 | 3→2 |
| 4 | 1228 | 293 | 2→1 |
| 5 | 1450 | 367 | 1→0 |

A ferramenta monitora `0x006B4` (u8, bandeiras restantes, correlação experimental), `0x00BA` (GS), `0x1ACC` (ponteiro), jogador X/Y, bola X/Y e posse. A direção e as tolerâncias de coleta são **hipóteses de controle**, não validadas em automação. A cada frame envia comandos ao controle 1; o próximo alvo é escolhido por `6 - remaining`, jamais por distância apenas. Não usa botões de chute ou passe.

## Uso (BizHawk)

1. Feche outros scripts Lua que usam joypad. Atualize com `git pull --ff-only origin main`.
2. Carregue `dribble_bot_v02.lua` da raiz do repositório no Lua Console. O bot inicia desarmado.
3. Abra DRIBBLE LV.1 manualmente. Assim que houver jogador em campo, execute no PowerShell na raiz:
   `Add-Content .\dribble_bot_commands_v02.txt 'ARM'`
4. Para interromper: `Add-Content .\dribble_bot_commands_v02.txt 'STOP'`. O script também desarma automaticamente se o GS/ponteiro mudar, o contador sair de 0..5, ocorrer salto ou reset, depois de 1800 frames, se permanecer junto ao waypoint sem coletar por mais de 90 frames ou se ficar parado apesar de movimentos solicitados por 45 frames.
5. Após teste, pare o Lua Console, anexe `dribble_bot_trace_v02.csv` e informe bandeiras coletadas e resultado mostrado na tela.

```powershell
Import-Csv .\dribble_bot_trace_v02.csv |
  Group-Object reason |
  Select-Object Name,Count |
  Format-Table -AutoSize

Import-Csv .\dribble_bot_trace_v02.csv |
  Select-Object -Last 40 frame,armed,reason,remaining,target,player_x,player_y,ball_x,ball_y,buttons |
  Format-Table -AutoSize
```

### Limitações
- Coordenadas são do **jogador no instante da coleta manual**, não posições exatas do objeto. A estratégia pode parar antes de acionar a coleta, atravessar um alvo ou perder a bola.
- Sem deteção de obstáculos, rota otimizada, orientação visual ou reconhecimento independente de SUCCESS; `remaining=0` só é interpretado sob GS=0 e PTR=0x0F00.
- Possessão `0x00A6` pode oscilar e não foi isoladamente validada no Challenge Mode.
- O registro é amostrado a cada 5 frames, com alguns eventos extras; logs são candidatos de controle, não prova de acerto.
- Se `ARM` for enviado antes de entrar no gameplay, o bot desarma por segurança.
- Para conferir a aplicação de controles, use o Input Display do BizHawk.
- Nenhum teste com BizHawk executado pela implementação. Testes locais sintéticos: `lua tests/test_dribble_waypoints_v02.lua`.
