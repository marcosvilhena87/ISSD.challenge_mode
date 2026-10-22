# DRIBBLE Goal Counter Validation v2 — 0x000DA2

Hipótese: `WRAM 0x0DA2` u16 little-endian (`My_Goal(s)`). A sondagem v1 observou `0 → 1` no frame **1415603**, simultaneamente a `GS=5`, após a quinta bandeira no frame **1415374**. Um gol foi confirmado visualmente posteriormente. Isso é **evidência de correlação em uma tentativa**, não exclusividade provada.

Este observador v2:
- Não utiliza `joypad.set`; execute junto ao bot existente.
- Usa sessões demarcadas pelo operador (`START`, `STOP`) para não misturar menus e partidas.
- Registra variação do contador e transições de GS/bandeiras com valores u16, bytes, posições e TIME/BONUS brutos.
- Guarda primeira transição positiva, GS e bandeiras no mesmo frame, além das marcações visuais.
- Compara sucesso visual e controles negativos. Classificações `positive_correlated_visual`, `increment_unverified`, `negative_control_no_increment`, `conflicting_negative_evidence`, `visual_goal_without_increment`, `unverified`. **Nenhuma delas ativa confirmação automática no DRIBBLE bot**.
- Arquivos `goal_counter_validation_v2.csv` (eventos) e `goal_counter_sessions_v2.csv` (resumo final).

## Protocolo no PowerShell
```powershell
git pull --ff-only origin main
# No BizHawk, abra goal_counter_validation_v2.lua além do bot de controle.
# Ao começar tentativa, com o observador já em execução:
Add-Content .\goal_counter_events_v2.txt 'START'
# Antes do chute, se útil:
Add-Content .\goal_counter_events_v2.txt 'BEFORE_SHOT'
# SOMENTE se viu o gol:
Add-Content .\goal_counter_events_v2.txt 'GOAL_VISUAL_CONFIRMED'
# Alternativa, para uma tentativa sem gol comprovada:
# Add-Content .\goal_counter_events_v2.txt 'SHOT_MISSED'
Add-Content .\goal_counter_events_v2.txt 'RESULT_SCREEN'
Add-Content .\goal_counter_events_v2.txt 'STOP'
Import-Csv .\goal_counter_validation_v2.csv | Format-Table -AutoSize
Import-Csv .\goal_counter_sessions_v2.csv | Format-List
```

**Importante:** envie comandos à medida que cada evento realmente acontecer. Se escrever todos rapidamente depois, as anotações terão o mesmo frame de leitura, e não será possível reconstruir o momento visual do gol. Um incremento já ocorrido antes de `START` não será contado. Para avaliar exclusividade, precisamos de tentativas com chute sem gol e novas inicializações, além de mais sucessos confirmados.

O parser ignora comandos antigos na inicialização; um resumo só é gravado após `STOP` ou novo `START`. Ausência de linha no resumo antes disso não significa falha.
