# Experimento PASS LV.1 v0.8.81 — alcance estático 7→10

Executar em branch experimental separada, criada da v0.8.80.

Quando a posse do jogador 7 for detectada com bola a <=18 WRAM e coordenadas válidas, registrar a distância inicial ao jogador 10 e suspender a rota automática, inclusive aproximação 7→10 e passe adicional normal. A rotina orienta por três frames no eixo dominante, solta os botões por dois frames, pressiona B por dois frames e observa passivamente durante 120 frames. Nenhum movimento posterior do portador é solicitado.

Eventos em `csv/pass_auto_v06.csv`:
- `static_710_range_started`: posições iniciais, distância, separação vertical, proximidade da bola e direção.
- `static_710_range_pass_pulse`: momento em que B foi aplicado.
- `static_710_range_aborted`: posse ou coordenadas inválidas antes do disparo.
- `static_710_range_observation_finished`: fim da observação; não comprova sucesso.

Conferir `csv/pass_reach_v0864.csv` e registros de recepção real para saber quem recebeu; distância maior que 180 WRAM é proposital para **testar** o alcance e não altera os limites do modo normal. A orientação de três frames pode causar deslocamento pequeno: comparar coordenadas antes/depois para determinar distância exata no instante do passe.

O modo experimental termina após uma tentativa e não deve ser incorporado automaticamente ao modo normal. Sem validação dinâmica BizHawk.
