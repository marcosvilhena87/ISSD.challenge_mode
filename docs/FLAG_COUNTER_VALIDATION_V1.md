# DRIBBLE Flag Counter Validation v1

O endereço `WRAM 0x006B4` apresentou cinco decrementos (5→0) numa tentativa com cinco bandeiras e SUCCESS relatado visualmente. **Ainda é hipótese**, pois falta controle sem coletas e reprodução independente de cada evento. Os endereços alternativos `0x00F2B` (incremental) e `0x00EE9` (decrescente) também são observados.

## Execução

1. Encerre todos os outros scripts Lua e rode `git pull --ff-only origin main`.
2. Carregue `flag_counter_validation.lua` sozinho no Lua Console do BizHawk antes da tentativa. O script inicia gravando `flag_counter_validation_v1.csv`; não precisa enviar comandos durante os 30 segundos.
3. Opcionalmente rotule, quando visivelmente aplicável, `START_MENU`, `PLAYING`, `NO_COLLECTION`, `FLAG_COLLECTED`, `SUCCESS`, `FAILURE`, `RETURN_MENU` usando `Add-Content .\flag_counter_events_v1.txt 'ROTULO'`. Eventos anteriores à inicialização são ignorados; o rótulo permanece até ser alterado.
4. Faça primeiro uma tentativa movendo sem coletar por alguns segundos; depois recolha uma bandeira e verifique a transição. Repita com sucesso e falha em sessões separadas e após reiniciar a ROM.
5. A captura é feita **a cada frame emulado**, mesmo fora do gameplay, para observar resets na entrada e saída. O arquivo pode ficar grande; interrompa o script Lua ao terminar. Nenhuma escrita na memória, nenhum input automático.

Examine apenas mudanças do contador e registros do operador:

```powershell
Import-Csv .\flag_counter_validation_v1.csv |
 Where-Object { $_.kind -eq 'operator' -or ($_.delta_06b4 -ne '' -and [int]$_.delta_06b4 -ne 0) } |
 Select-Object session,frame,kind,operator_label,game_state,controlled_pointer,remaining_06b4,delta_06b4,alternate_0f2b,delta_0f2b,alternate_0ee9,delta_0ee9,player_x,player_y |
 Format-Table -AutoSize
```

`candidate_phase` usa apenas GS=0 e ponteiro=0x0F00, ainda sem flag de presença validada. As amostras rotuladas por operador são observações visuais, não detector independente. `remaining_06b4=0` por si só **não** confirma sucesso. Distinguir transições do início/fim de coletas requer análise de frame e repetição.

Teste sintético: `lua tests/test_flag_counter_validation.lua`.
