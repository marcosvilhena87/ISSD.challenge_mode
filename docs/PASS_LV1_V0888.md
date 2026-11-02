# PASS LV.1 v0.8.88 — passe direto 9→7 e continuidade 7→10

Base v0.8.87. Quando o portador observado é o jogador 9 e o jogador 7 ainda não foi visitado, a rota normal de aproximação fica temporariamente bloqueada e a rotina direcional tenta 9→7, desde que a geometria esteja adequada: distância entre 35 e 410 WRAM, separação vertical <=100 WRAM, bola próxima do portador <=18 WRAM e corredor sem jogador bloqueador. O comando é Control Pad + B simultaneamente após uma curta orientação (3 frames) e liberação (2 frames).

O evento `relay_97_started` indica a seleção do passe e registra distância, dx/dy e proximidade da bola. `long_710_directional_b` marca o comando de lançamento; `long_710_motion_result` traz os deslocamentos registrados dos dois jogadores; `long_710_receiver_observed` identifica o receptor quando a posse é observada. Uma ausência de confirmação não equivale a sucesso. O lançamento pode ser impedido pelo corredor e demais limites de segurança.

Após 9→7, a regra de avanço controlado de até 18 frames ou 40 WRAM do portador 7 antes do passe 7→10 continua disponível. O rearmamento com cooldown de 36 frames e limite de duas tentativas por par continua valendo; o último jogador ausente mantém prioridade.

A implementação requer validação dinâmica no BizHawk. Não implica conclusão do desafio.
