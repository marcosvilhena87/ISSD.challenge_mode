# PASS LV.1 v0.8.92 — validar bola em relação ao portador real

Base: v0.8.91, preservando geometria por coordenadas, deslocamentos diagonais, proteção de corredor, passe Control Pad+B e recuperação da sequência.

## Correção
Na fase de preparação `face`, o controle antigo chamava `ball_gap_710(sample_for_auto)`, que sempre calculava a distância da bola ao **jogador 7**, mesmo em passes como 9→7 e 10→11. Agora usa `carrier_gap(sample_for_auto,long_710.origin)`, calculando a distância da bola ao jogador que realmente está tentando passar.

A tentativa deixa de ser cancelada só porque a bola está distante do receptor, desde que permaneça perto do portador verdadeiro (até 18 WRAM).

## Diagnóstico
No evento `long_710_aborted` distinguimos:
- `reason=holder_changed`: portador observado não corresponde ao emissor;
- `reason=invalid_coordinates`: portador/receptor sem geometria válida;
- `reason=missing_ball_or_origin`: dados insuficientes para medir posse;
- `reason=ball_out_of_range`: bola distante mais de 18 WRAM do emissor.

Os logs também apresentam `actual_holder`, `ball_gap`, `origin` e `target`. O evento `relay_lane_open_pass_queued` continua encaminhando a tentativa para a preparação; em cada frame, a geometria e o corredor são novamente conferidos. O passe usa somente uma direção cardinal dominante mais B simultaneamente.

Requer teste no BizHawk; eventos de recepção espacial não são confirmação oficial de sucesso do desafio.
