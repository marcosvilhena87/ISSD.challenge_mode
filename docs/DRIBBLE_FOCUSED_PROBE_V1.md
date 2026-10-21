# DRIBBLE LV.1 Focused Probe v1

Sondagem independente e somente leitura da WRAM para observar DRIBBLE LV.1, que tem 30 segundos e apenas um jogador visível do time do usuário. Os endereços têm origem em [ISSD.mapping/docs/RAM_MAP.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/RAM_MAP.md). Este experimento **não confirma** que o jogador visível é sempre o registro No.11 nem que os indicadores de partida normal distinguem os estados de Challenge Mode.

## Procedimento

1. Feche `main.lua`, `gameplay_probe.lua` e todos os outros scripts Lua.
2. Na raiz do repositório, execute `git pull --ff-only origin main`.
3. Abra `dribble_focused_probe.lua` no Lua Console do BizHawk **antes** de iniciar o desafio. O console informa `dribble_lv1_focused_v1.csv`.
4. Com o monitor em execução, entre em DRIBBLE LV.1 e confirme CHALLENGE START.
5. Durante os 30 segundos, movimente o único jogador para os lados e para cima/baixo, conduza a bola quando possível. **Não é necessário enviar comandos no PowerShell.**
6. Deixe o tempo acabar ou conclua o desafio, observe visualmente a tela de saída e interrompa o script depois de voltar ao menu.
7. Repita em nova sessão para comparar valores estáticos/residuais.

```powershell
Import-Csv .\dribble_lv1_focused_v1.csv |
  Select-Object -Last 30 frame,gameplay_active_u8,game_state,stadium_id,ball_x_s16,ball_y_s16,player11_x,player11_y,ball_dx,player_dx,player_dy,distance,read_errors |
  Format-Table -AutoSize
```

## Amostragem e interpretação

Uma amostra a cada 5 frames emulados (~12 amostras/s a 60 FPS), continuamente até parar o script. O CSV contém sessão, frame, frames decorridos desde **o início do probe**, leituras da bola tanto s16 quanto u16, No.11 X/Y signed, `0x0006` u8 **e** u16, `0x00BA` u16, `0x0086` s16, e os quatro campos de geometria (`0x12A2`, `0x12A4`, `0x12F2`, `0x12D8` u16). Diferenças entre amostras, distância euclidiana em unidades brutas, e falhas de leitura também são registrados.

`elapsed_seconds_60fps` é tempo nominal emulado desde que o script iniciou, **não o cronômetro do desafio**. O monitor não detecta automaticamente início/fim; a transição deve ser correlacionada com a observação visual ou vídeos, timestamps/frames. Coordenadas válidas não provam visibilidade do registro No.11. Distância bruta não é calibrada para pixels. `gameplay_active_u16` é uma leitura exploratória, não substitui o tipo u8 canônico. Nenhuma modificação é feita na memória do jogo ou no ISSD.mapping.

Teste sintético: `lua tests/test_dribble_focused_probe.lua`.
