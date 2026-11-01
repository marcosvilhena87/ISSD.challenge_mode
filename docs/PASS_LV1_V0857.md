# PASS LV.1 v0.8.57 — confirmação contextual pós-chute, derivada do DRIBBLE

Base: v0.8.56 (cadeia espacial 10/10, bônus 30→29, X emitido). Não altera seleção de jogadores, deslocamento, passes nem direção de finalização.

## Implementação
O módulo `lua/challenge/pass_goal_evidence_v0826.lua` reutiliza o núcleo `challenge.goal_evidence_v4`, empregado pelo DRIBBLE, sem importar suas hipóteses específicas sobre cinco bandeiras e contexto GS. No frame de X a rotina `GoalEvidence.mark_shot` fixa o contador base (WRAM 0x0DA2/0x0DA3) e o marcador `SHOT_STARTED`, reinicializando a comparação do contador no instante do disparo para evitar falsos incrementos anteriores. Monitora leituras de contador, bytes baixo/alto, estado GS, ponteiro e marcador de tempo, quando disponíveis, pelos **300 frames seguintes**, mesmo se a automação de passes estiver desabilitada. Escrita de eventos em `csv/pass_goal_evidence_v0826.csv` e `csv/pass_auto_v06.csv` (eventos `goal_post_shot_*`), com coleta periódica a cada 30 frames e imediata quando existe transição importante.

## Classificação
- `pass_contextual_goal_candidate`: um incremento unitário após X, associado aos marcadores já observados de 10/10 e início de contagem regressiva, sem conflito do contador. É **evidência contextual candidata**, não confirmação visual ou oficial.
- `increment_not_validated_for_pass`: incremento sem os critérios de contexto do PASS.
- `multiple_increments_unverified`: mais de um incremento; resultado inconclusivo.
- `counter_conflict_unverified`: reset ou divergência low/high.
- `no_increment_in_window`: nenhum incremento observado até o fim de 300 frames; não significa por si só que o chute errou.
- `awaiting_post_shot_observation`: janela ainda em curso.

Assim como no Dribble, a leitura de contador não equivale automaticamente a aprovação do desafio, pontuação ou gol confirmado pelo jogo. Para confirmação forte, associar vídeo/sinal de tela de gol com o contador contextual.

## Testes
`python -m unittest tests/test_pass_v0857_static.py`. Testes estáticos cobrem instrumentação e categorias; a execução real no BizHawk e uma análise visual de gol permanecem necessárias.
