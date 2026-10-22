# DRIBBLE Bot v0.3.1 — Goal & Score Validation

Preserva a política de cinco bandeiras da v0.2.2 e a aproximação/chute experimental da v0.3. A v0.3.1 concentra-se em observabilidade: registro único de eventos, medição da duração por frames, leitura dos segundos BCD provisórios e resumo por tentativa.

Os endereços `0x014F0` (TIME) e `0x014F4` (BONUS TIME) são candidatos BCD de alta confiança, **não mapeamentos canônicos**. Frações em `0x014F2` e `0x014F6` são lidas como u16 brutos, sem decodificação de centésimos. Registro de saída do gameplay não equivale a gol confirmado.

## Execução

1. Encerre os scripts que controlam inputs; execute `git pull --ff-only origin main`.
2. Carregue `dribble_bot_v031.lua` no Lua Console do BizHawk, entre em DRIBBLE LV.1 e arme:
   `Add-Content .\dribble_bot_commands_v031.txt 'ARM'`
3. Após observar a tela de recorde desta mesma tentativa, confirme o gol:
   `Add-Content .\dribble_bot_commands_v031.txt 'CONFIRM_GOAL'`
4. Para a pontuação exibida, por exemplo 401:
   `Add-Content .\dribble_bot_commands_v031.txt 'SCORE:401'`
5. Se não houver confirmação, **não** envie CONFIRM_GOAL. O resultado fica como `unverified`.
6. Para finalizar a tentativa antes do prazo de 300 frames após a saída do gameplay:
   `Add-Content .\dribble_bot_commands_v031.txt 'STOP'`

O script gera `dribble_bot_trace_v031.csv` com as leituras observadas durante o controle, e `dribble_bot_summary_v031.csv` com exatamente uma linha por tentativa finalizada; a linha é gravada em STOP, nova ARM ou após uma janela de 300 frames de observação pós-saída. Use as confirmações dentro dessa janela. O código não infere gol automaticamente. O comportamento do chute continua experimental, portanto mantenha o jogo sob observação.

Verifique com `lua tests/test_dribble_goal_v031.lua` se houver interpretador Lua. Testes sintéticos não substituem BizHawk.
