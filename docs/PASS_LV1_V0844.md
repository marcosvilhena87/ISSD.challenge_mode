# PASS LV.1 v0.8.44 — movimento relativo e separação mínima global

Base: v0.8.43 (branch `fix/pass-lv1-eight-nine-feedback-v0843`).

## 8→9: feedback por velocidades relativas

A captura WRAM dos dois jogadores já inclui X/Y. O controlador agora calcula a projeção do deslocamento do **portador** ao longo do vetor inicial até o receptor (`holder_toward`), e a projeção de deslocamento do **receptor** para longe do portador (`receiver_away`). A diferença `relative_closing = holder_toward - receiver_away` representa uma estimativa local de aproximação.

- Se o portador avança (>0,5 unidade projetada), não atribuir a regressão observada ao direcional somente porque o receptor correu mais rápido.
- Se a distância aumenta >1,5 e o portador não avança, contar uma amostra de falha de movimentação do portador e penalizar a direção.
- Interromper depois de duas falhas do portador ou crescimento líquido acumulado >65 unidades. Permanecem limites anteriores de tempo e segurança e a seleção geométrica de UP/RIGHT.
- Evento `approach_89_relative_feedback` inclui deslocamento do portador, fuga do receptor, fechamento relativo, variação da distância e falhas do portador. `approach_89_regression_stop` indica encerramento.

## Todos os passes: distância mínima global

`Feet.MIN_PASS_DISTANCE = 24` unidades de coordenadas WRAM é aplicado por `Feet.measure`/`Feet.check` para **qualquer portador/receptor**, sem exceções. Passes entre jogadores mais próximos do que isso retornam `too_close` e não são executados. Não equivale a exigir separação mínima durante todo movimento de aproximação, mas sim no momento de validar o passe. Eventual relaxamento de distância máxima não reduz o mínimo. `pass_min_gap_check` documenta distância e resultado na seleção de receptor.

O valor 24 é **parâmetro experimental**, não uma distância comprovada pelo motor do jogo. Ajustar somente após avaliação dos logs.

Mantidos UP isolado → neutro → UP+B (6→3), pré-Down → Down+B (4→5), RIGHT até oito frames (5→8), seleção geométrica (8→9), limite absoluto de 210 frames e monitor do bônus/finalização. Requer validação real no BizHawk.
