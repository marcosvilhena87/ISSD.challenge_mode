# PASS LV.1 v0.8.87 — redistribuir deslocamento do receptor 10 para o portador 7

Base v0.8.86. Quando o passe direcional programado é 7→10 e a geometria inicial é autorizada, o controlador entra na fase `advance` antes do passe. O jogador 7 caminha na direção do 10 por **até 18 frames ou 40 WRAM** de deslocamento medido, interrompendo caso perca a posse ou a geometria fique inválida. Depois executa a orientação de 3 frames, liberação de 2 frames e **Control Pad + B simultaneamente** por 2 frames.

Para reduzir o risco de travar a cadeia ao alcançar 9/10, a rotina passa de `done` a `ready` após um resfriamento de 36 frames. Cada par portador–receptor pode tentar no máximo duas vezes por sessão; cada nova tentativa passa por verificações de corredor, posse e distância. A recuperação exclusiva do jogador ausente e a devolução 10→7→10 continuam presentes.

Eventos no `csv/pass_auto_v06.csv`: `long_710_advance_finished` (dx/dy do jogador 7 e do 10 antes do lançamento), `long_710_advance_aborted`, `long_710_motion_result` (dx/dy de ambos entre disparo inicial e recepção observada), `long_pass_rearmed`, `long_710_directional_b`, `long_710_receiver_observed`.

**Importante:** redistribuir deslocamento é o objetivo do experimento, não resultado garantido. O jogador 10 é controlado pelo próprio jogo; a medição avalia se ele precisou andar menos. Faltam testes dinâmicos no BizHawk e validação oficial do desafio.
