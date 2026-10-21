# DRIBBLE LV.1 State Validation v1

Sonda read-only para testar hipótese `Game State (0x00BA) + My Controlled Player (0x1ACC)` em DRIBBLE LV.1. A observação anterior encontrou `Game State=0,5,6` e `My Controlled Player=0x0F00/0x0000`, mas **não** identificou sucesso ou falha automaticamente.

Execute `dribble_state_validation.lua` sozinho no Lua Console do BizHawk, antes de iniciar a tentativa. O script grava `dribble_state_validation_v1.csv` desde a inicialização, com amostragem a cada cinco frames, e monitora novos eventos de `dribble_state_events_v1.txt`. Eventos antigos são ignorados. Continua durante a saída, sem parar após 30 segundos.

Em uma tentativa que termine por tempo esgotado, marque o resultado visual quando ele estiver na tela; numa segunda tentativa, conclua o desafio e marque o sucesso visualmente. **As marcações não são detectadas automaticamente**. Exemplos:

```powershell
Add-Content .\dribble_state_events_v1.txt 'START_MENU'
Add-Content .\dribble_state_events_v1.txt 'PLAYING'
Add-Content .\dribble_state_events_v1.txt 'FAILURE'
Add-Content .\dribble_state_events_v1.txt 'RETURN_MENU'
```

Na tentativa de sucesso use `SUCCESS` no lugar de `FAILURE`. Se o cronômetro não permitir eventos em tempo real, grave vídeo ou anote o frame mostrado pelo BizHawk e marque o resultado logo após aparecer. Não envie `SUCCESS` apenas por presumir que concluiu: confirme a tela. `TRANSITION` e `UNKNOWN` são rótulos adicionais.

```powershell
Import-Csv .\dribble_state_validation_v1.csv |
  Where-Object { $_.kind -eq 'operator' -or $_.state_changed -eq '1' -or $_.pointer_changed -eq '1' -or $_.field_changed -eq '1' } |
  Select-Object session,frame,operator_label,game_state,my_pointer_hex,field_length,field_width,state_changed,pointer_changed,candidate_state |
  Format-Table -AutoSize
```

Compare sessões de **sucesso, falha e retorno ao menu** separadamente, preferencialmente repetidas após reinício. O campo `candidate_state` tem só quatro resultados possíveis: `possible_playing`, `possible_transition`, `possible_post_game_or_menu`, `unknown`. Nenhum equivale a sucesso/falha confirmados, nem implica flag autônoma de tela. As coordenadas e referências podem ser residuais. Evite promover o catálogo canônico sem controles.

Teste sintético: `lua tests/test_state_validation.lua`.
