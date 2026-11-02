# PASS LV.1 v0.8.69 — recuperação direcional controlada 5→8

Base v0.8.68. Na sessão anterior, RIGHT em 5→8 apresentou projeção -8 WRAM em uma janela e o controlador interrompeu toda a cadeia.

## Alteração
- O guard `Ordered.guard_right` agora tolera até duas rajadas fortemente regressivas; só a terceira regressão adversa consecutiva suspende RIGHT. Uma rajada com progresso zera o contador de regressões consecutivas.
- Uma suspensão persistente em **5→8** pode ativar até duas retomadas com orçamento adicional de até 16 frames cada. A direção continua a ser determinada pela posição WRAM relativa do portador e receptor, com preferência RIGHT quando o receptor está à direita; não se força um movimento contrário à geometria. A decisão é registrada em `approach_58_controlled_retry` com dx, dy, distância e orçamento restante.
- Teto absoluto de 210 frames preservado. Após esgotar as retomadas ou orçamento, permanece a parada de segurança. Este experimento não remove bloqueios por falhas persistentes.
- Em **4→5**, `pass_45_ball_relative_at_b` grava os offsets X/Y da bola em relação ao portador no frame do evento `pass_pulse`; isso ajuda a investigar a alternância entre passe curto e longo. Não é um endereço WRAM de orientação.
- Não modifica as outras rotas, autorização do passe antecipado 7→10, medição de caminhada, nem a referência geométrica do estádio.

## Validar no BizHawk
Conferir `csv/pass_auto_v06.csv` (eventos `approach_right_feedback`, `approach_58_controlled_retry`, `pass_45_ball_relative_at_b`) e `csv/pass_reach_v0864.csv`. Comparar o número de passagens concluídas em 5→8 e a direção/velocidade WRAM efetivas do jogador 5. Testes adicionados são **estruturais**, não substituem validação dinâmica.
