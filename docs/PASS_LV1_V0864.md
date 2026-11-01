# PASS LV.1 v0.8.64 — alcance com movimento dos dois jogadores

Base v0.8.63. Mantém os controles de movimento, passe, gol e suas proteções, alterando apenas a telemetria.

O novo `csv/pass_reach_v0864.csv` exporta quatro grupos de indicadores por tentativa:
1. `carrier_walk`: soma do caminho do portador antes de pressionar B;
2. `receiver_walk`: soma do deslocamento observado do receptor *depois* do B e até o desfecho;
3. `closest_ball_receiver_gap` e `final_ball_receiver_gap`: distância bola–receptor, respectivamente mínima e ao final;
4. `combined_walk`: soma dos caminhos do portador e receptor, para classificar eficiência conjunta. `initial_gap`, `ball_path` e `ball_max_displacement` continuam separados, pois o caminho curvo da bola não equivale ao afastamento da origem.

Em transferências candidatas para o receptor planejado, `receiver_walk<=5` é `direct_candidate`; acima disso, `adjusted_candidate`. Transferência a outro jogador ou sem receptor confirmado é `other_or_no_receiver`. Todas são **categorias espaciais experimentais**; distância mínima pequena não prova toque ou recepção reconhecida pelo jogo.

**Limitação importante:** movimento do receptor pode resultar da IA do jogo e não de um comando do bot. A métrica descreve movimento observado, não esforço causado pelo controlador. Não forçar passes mais longos nem mudar o limiar de alcance com base só nesta coleta. Comparar taxas de chegada por distância inicial e faixas de caminhada após várias execuções.

Teste estrutural: `python -m unittest discover -s tests -p test_pass_v0864_static.py`. Validar no BizHawk.
