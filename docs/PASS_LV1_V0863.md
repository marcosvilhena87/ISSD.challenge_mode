# PASS LV.1 v0.8.63 — estudar alcance com caminhada mínima

Base: v0.8.62. A rota de passes, aproximação 7→10 com RIGHT contínuo, UP+RIGHT 6→7 e verificação pós-chute permanecem inalteradas.

## Medições passivas
Arquivo: `csv/pass_reach_v0863.csv`.

- `plan`: par de jogadores selecionado e distância euclidiana inicial; ainda não confirma passe possível.
- `shot`: B emitido; `carrier_walk` acumula a **soma das distâncias entre posições sucessivas do portador** desde o plano até o chute, mesmo se o portador fizer uma curva.
- `flight`: amostras a cada frame nos 12 primeiros frames depois de B, e a cada 5 depois disso; `ball_path` é a soma dos deslocamentos consecutivos amostrados da bola; `ball_max_displacement` é o máximo afastamento em linha reta da posição de disparo.
- `transfer_candidate_observed` ou outra conclusão: receptor observado quando disponível, e medidas acumuladas; resultados são candidatos espaciais e não prova oficial de passe. Tentativas sem desfecho fecham por timeout em até 180 frames.

## Análise proposta
Agrupar por `from_player,planned_player`. Restringir inicialmente a `event=transfer_candidate_observed` e `observed_player=planned_player`; classificar separadamente interceptações ou desvios. Para medir **alcance com caminhada mínima**, comparar `initial_gap` e `carrier_walk` ao momento do B, com estratos como caminhada <5, <15 e <30 WRAM. Calcular máximos observados, quantis e taxa de chegada — não confundir valores máximos isolados com alcance garantido.

As verificações geométricas existentes já permitem B quando o receptor está ao alcance; este experimento mede se isso resulta em recepção real, sem arriscar alterar diretamente o limiar de passe de 190 WRAM. Depois de reunir sessões suficientes, avaliar uma política de tentar B mais cedo de forma controlada. Não há prova de alcance máximo em uma única sessão.

Teste estrutural: `python -m unittest discover -s tests -p test_pass_v0863_static.py`.
