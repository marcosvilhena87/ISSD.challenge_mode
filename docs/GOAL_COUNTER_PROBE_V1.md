# Investigação de 0x000DA2 — My_Goal(s), observação v1

Hipótese informada pelo operador: `000DA2 w u 0 WRAM My_Goal(s)`: word 16-bit unsigned, início observado 0. **Ainda não validado** para a ROM e modo DRIBBLE LV.1. Cuidado: `0x0DA2` é um offset de WRAM, não o endereço do registrador PPU.

`goal_counter_probe_v1.lua` é **passivo**: apenas lê a memória uma vez por frame e registra eventos de alteração do candidato, mudanças de flags/GS e eventos visuais indicados em arquivo separado. Não envia comandos nem declara gol automaticamente.

Comparar três contextos: antes do chute, depois de um gol *visualmente confirmado* e após falha/saída sem gol. Registrar também uma nova tentativa e a tela de resultados; mudanças de modo podem sobrescrever memória. Se `da2_u16` incrementar apenas quando ocorre gol próprio, e persistir durante a transição, repetir ao menos 3 vezes. Verificar se contagem muda após gol do adversário e se leitura u8 baixo/alto acompanha u16 little-endian. Só depois considerar integrar como evidência de gol ao bot. Verificar reset e placar antes de concluir.

## Protocolo
```powershell
git pull --ff-only origin main
# Abra goal_counter_probe_v1.lua no Lua Console do BizHawk, em paralelo ao bot (somente ele controla joypad).
Add-Content .\goal_counter_events_v1.txt 'BEFORE_SHOT'
# Observe o gol visualmente
Add-Content .\goal_counter_events_v1.txt 'GOAL_VISUAL_CONFIRMED'
Add-Content .\goal_counter_events_v1.txt 'RESULT_SCREEN'
Import-Csv .\goal_counter_probe_v1.csv | Format-Table -AutoSize
```
Para tentativa sem gol, use `SHOT_MISSED` e `NO_GOAL_EXIT`, de acordo com o que efetivamente observar. Não inventar evento nem disparar confirmação automática. O script ignora eventos antigos na inicialização.
