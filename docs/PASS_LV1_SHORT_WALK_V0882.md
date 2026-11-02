# PASS LV.1 v0.8.82 — teste de alcance 7→10 após avanço curto

Branch experimental independente baseada na v0.8.81.

Quando o jogador 7 recebe a bola com distância bola–portador <=18 WRAM e coordenadas válidas, o controle automático da rota é suspenso. Em vez de tentar o passe imediatamente da posição de recepção, executa um pequeno avanço cardinal rumo ao receptor 10. Para em 12 frames ou 24 WRAM de deslocamento medido (o primeiro limite alcançado). Não utiliza Dash. Se perder a posse ou a geometria ficar inválida, cancela sem B.

Ao concluir a caminhada, registra `static_710_short_walk_finished`, orienta por três frames, solta os botões por dois frames e pressiona B por dois frames. A rotina observa depois aproximadamente 120 frames sem novo movimento e registra a trajetória da bola a cada dois frames em `static_710_ball_trajectory`, incluindo posição, deslocamento desde o passe, máximo deslocamento, menor distância até o jogador 10 e portador observado. `static_710_range_observation_finished` resume os valores, mas não prova conclusão de passe.

Os eventos são gravados em `csv/pass_auto_v06.csv`; recepções precisam ser conferidas também nos registros espaciais. Comparar com o experimento anterior (distância inicial ~322 WRAM), lembrando que as posições iniciais podem variar entre sessões. Validar no BizHawk: testes estruturais não comprovam o comportamento.
