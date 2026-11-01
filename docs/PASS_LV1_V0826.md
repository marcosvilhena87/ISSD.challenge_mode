# PASS LV.1 v0.8.26 — evidência passiva de gol após 10/10 + bônus + X

A versão preserva as decisões de movimento/passe da v0.8.25 e aproveita o componente de contador do DRIBBLE, agora no nome compartilhado `lua/challenge/goal_evidence_v4.lua`. O executor independente `lua/goal_evidence_v4.lua` **já existia** e mantém seu nome. Foram atualizados os imports do `lua/dribble_bot.lua`, do executor independente e dos testes conhecidos para o novo caminho. A migração elimina o arquivo `lua/challenge/dribble_goal_evidence_v4.lua`.

## PASS
Ao ARM, captura valor de referência do candidato u16 na WRAM `0x0DA2` e bytes `0x0DA2`/`0x0DA3`. Monitora também `GS` u16 `0x00BA`, ponteiro u16 `0x1ACC` e leitura u8 `0x006B4` como contexto exploratório, **sem exigir os valores específicos do DRIBBLE**. Depois do primeiro X, observa 300 frames emulados. Todos os resultados são candidatos: mesmo um incremento de +1 correlacionado com 10/10, bônus e X não é confirmação visual de gol nem vitória oficial.

CSV `csv/pass_goal_evidence_v0826.csv`: `shot_x_issued`, `post_shot_sample` (a cada dez frames), `goal_counter_increment`, `goal_counter_reset_or_decrease`, `byte_mismatch`, `observation_window_closed`. Inclui referência e variação do contador, GS, ponteiro, restante, frames de conclusão/bônus/chute e classificação. O acompanhamento é passivo e não injeta controles após X.

## Testar
Selecionar a branch `feature/pass-lv1-goal-evidence-v0826`, reiniciar `main.lua` em BizHawk, entrar em PASS LV.1 e enviar `TRIGGER:A`, `CALIB:A`, `PASSBTN:B`, `DIRECTION:AUTO`, `FINISH:ON`, `AUTO:ON`, `ARM` ao arquivo de comandos existente. Deixar passar 300 frames após o chute X. Conferir o CSV e, separadamente, observar visualmente gol/tela de resultado. Teste estático: `python -m unittest tests/test_pass_v0826_static.py` se o Python local for configurado para o pacote de testes, ou `python -m unittest discover -s tests -p test_pass_v0826_static.py`.

Não executado em BizHawk nesta sessão. O estado do DRIBBLE e seu contexto de cinco bandeiras permanecem próprios dele.
