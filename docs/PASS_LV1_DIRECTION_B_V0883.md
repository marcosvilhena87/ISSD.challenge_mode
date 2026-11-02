# PASS LV.1 v0.8.83 — Control Pad + B simultâneos

**Correção principal:** o teste experimental 7→10 deve apertar Control Pad (direção cardinal escolhida) **e B no mesmo frame**. A v0.8.82 enviava B isoladamente, portanto a pequena variação da bola não era evidência confiável do alcance do passe.

Fluxo preservado: recepção detectada do 7, caminhada curta de até 12 frames/24 WRAM sem Dash, orientação de 3 frames, 2 neutros, pulso conjunto direção+B em 2 frames, observação passiva por ~120 frames. A aproximação longa permanece desabilitada após disparo do experimento.

Telemetria em `csv/pass_auto_v06.csv`:
- `static_710_short_walk_finished`: direção solicitada, dx/dy efetivos, distância no final da caminhada.
- `static_710_range_pass_pulse`: comando simultâneo e distância inicial.
- `static_710_actual_input`: estado de Up/Down/Left/Right e B durante os dois frames do pulso.
- `static_710_ball_trajectory`: posição da bola, deslocamento máximo, menor distância ao 10, portador observado.
- `static_710_range_observation_finished`: término da janela, **sem prova automática de conclusão**.

Comparar alcance e receptor observado com v0.8.82 e considerar interferências da rotina de finalização em sessões onde o algoritmo registre 10/10. A branch é experimental; ainda requer teste no BizHawk.
