# PASS LV.1 v0.8.71 — recepção inesperada e aproximação 7→11

Base: v0.8.70. Na sessão precedente o passe planejado 6→7 chegou ao jogador 10; a sequência prosseguiu 10→7 e o próximo receptor não visitado passou a ser 11. A tentativa 7→11 terminou em ~427,87 WRAM por regressão.

## Alterações
- Toda recepção divergente produz `route_unexpected_receiver_reconcile` indicando origem, destino planejado, jogador realmente observado, visita e próximo jogador ainda não visitado.
- A seleção continua usando as visitas observadas; se 10 recebeu antes de 7, não se força 7→10 novamente. É esperado 10→7, depois 7→11 quando 11 é o único não visitado.
- Em 7→11, priorizar direção cardinal apontada pelo vetor WRAM do receptor, sem herdar RIGHT calibrado para 7→10.
- Se após pelo menos 24 frames a distância estiver >15 WRAM acima da inicial e >28 acima da melhor, interromper sem B: `pair_711_net_regression_stop`.
- Limite global de 210 frames e restrição específica de 160/180 WRAM para 7→10 permanecem intactos.

## Validação
Reiniciar main.lua e observar `csv/pass_auto_v06.csv` (evento de reconciliação, `approach_aborted`) e `csv/pass_reach_v0864.csv` (receptor real). Os testes adicionados são estáticos; resultados de jogo, 10/10 e gol não estão comprovados.
