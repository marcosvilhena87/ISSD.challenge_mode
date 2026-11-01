# PASS LV.1 v0.8.23 — aproximação orientada por progresso

A v0.8.22 conseguiu seis passes 6→2→3→4→5→8→9 antes de atingir 90 movimentos de aproximação ao jogador 7.

A v0.8.23 mantém a ordem preferencial e a recuperação adaptativa de receptores inesperados. Em cada ciclo de aproximação aplica um frame direcional e um neutro. No frame neutro mede a distância ao receptor atual, guarda a distância inicial, a última distância e a melhor distância. Se seis avaliações consecutivas não reduzirem a distância em pelo menos 0,5 unidade, alterna o eixo de aproximação entre horizontal e vertical. A cada duas trocas de eixo eleva um nível dos limites de distância e diagonal da v0.8.19, com teto 290/120 e sem emitir B durante aproximação.

A proteção contra bola afastada do portador continua; após alcançar um alvo válido continuam sendo obrigatórias as barreiras de estabilidade de posse e alinhamento A–bola–B. A aproximação segue limitada a 90 pulsos por tentativa. O estado de progresso reinicia após cada transferência observada.

Logs no csv/pass_auto_v06.csv: approach_step, approach_progress, approach_axis_switched, limits_expanded, approach_timeout. Comparar distância inicial/melhor distância, novos participantes, número de erros de recepção e tempo restante.

Limitação: os limites são heurísticos e o jogo não possui vetor físico de velocidade validado. A mudança ainda não foi validada em BizHawk.
