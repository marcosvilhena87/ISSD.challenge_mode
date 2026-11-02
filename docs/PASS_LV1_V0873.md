# PASS LV.1 v0.8.73 — Dash (Y) no portador 7

Base: v0.8.72. Adiciona Y junto à direção cardinal apenas enquanto o jogador 7 se aproxima do receptor 10. Pressionar Dash não altera a escolha de direção nem permite passes mais longos.

## Implementação
- Durante `approach_step` 7→10, o controlador adiciona `Y=true` à direção escolhida.
- `burst_direction` continua a representar apenas Right/Left/Up/Down; Y não substitui uma direção.
- Nunca enviar Y com B ou X; ao encerrar uma rajada ou entrar em fase de passe o botão Y é liberado.
- Evento `approach_710_dash_start` documenta cada rajada acelerada.
- Preservados o alvo 160, o limite de passe 180, a geometria lateral e o teto absoluto de 210 frames.

## Medição no BizHawk
Comparar avanço real do jogador 7 por frame (holder_dx/frames) e deslocamento do jogador 10 com a v0.8.72. Validar se Dash aumenta a velocidade, se a posse é mantida e se a distância cai. Dash Y neste jogo é hipótese experimental até confirmado pelos logs, não garantia de aceleração.
