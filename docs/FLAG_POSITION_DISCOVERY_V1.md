# DRIBBLE Flag Position Discovery v1

Usa a correlação experimental de `WRAM 0x006B4` (u8) com bandeiras restantes: tentativa com zero coletas permaneceu em 5; uma coleta gerou 5→4 no gameplay; cinco coletas geraram 5→0 com SUCCESS. **Ainda não são coordenadas internas das bandeiras.** Cada posição registrada corresponde à posição do jogador e da bola no frame da mudança do contador, que pode ocorrer a alguma distância do objeto.

## Captura

1. Feche outros scripts Lua; execute `git pull --ff-only origin main`.
2. Carregue `flag_position_discovery.lua` no Lua Console antes de iniciar DRIBBLE LV.1.
3. Colete as cinco bandeiras manualmente. O script lê somente a memória a cada frame e grava `flag_positions_v1.csv`. Não precisa de comando ARM nem altera o controle.
4. Pare o Lua depois do resultado. Analise:

```powershell
Import-Csv .\flag_positions_v1.csv |
  Where-Object { $_.event -eq 'collection_candidate' } |
  Select-Object session,frame,collection_index,remaining_before,remaining_after,player_x,player_y,ball_x,ball_y |
  Format-Table -AutoSize
```

Faça também `Import-Csv .\flag_positions_v1.csv | Group-Object session,event | Select-Object Count,Name`. Para examinar os cinco frames anteriores/posteriores a uma mudança, filtre por frame numericamente.

A classificação exige duas leituras consecutivas com `GS=0`, `My Controlled Player=0x0F00` e contador 0..5. Mudança -1 gera `collection_candidate`; outras mudanças geram rótulo de cautela; zero fora de gameplay nunca conta como coleta. Arquivo integral por frame permite auditoria do antes/depois, sem anexar dump de WRAM. O registro de arquivo a cada frame pode reduzir o desempenho.

Próxima etapa: repetir trajetórias alternativas para verificar consistência espacial das cinco regiões; só depois buscar coordenadas reais de objetos de bandeira na WRAM. Testes de Lua são sintéticos, não demonstram funcionamento no BizHawk.
