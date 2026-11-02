# PASS LV.1 — v0.8.91: direção e aproximação para todos os pares

Base v0.8.90. O controlador usa as coordenadas WRAM do portador e receptor, com X crescente para a direita e Y crescente para baixo. A rotina de movimentação pode emitir dois botões direcionais no mesmo frame (diagonal: Right+Up, Right+Down, Left+Up, Left+Down) quando os dois desvios superam 24 WRAM. **Na execução do passe B, mantém apenas a direção cardinal dominante junto com B**, como nos experimentos anteriores.

O reposicionamento do corredor avalia oito deslocamentos projetados, quatro cardinais e quatro diagonais. Quando um reposicionamento termina e o corredor está livre, a rotina muda imediatamente para a fase de preparação do passe, sem exigir um novo ciclo de reposicionamento. Antes de cada fase da preparação verifica novamente o bloqueador: se a linha voltou a ser obstruída, cancela o lançamento e registra `relay_pass_cancelled_blocker` em vez de pressionar B. Um novo ciclo é permitido após um intervalo curto.

A lógica abrange os pares direcionais tratados pelo controlador, incluindo 9→7, 7→10, devolução 7→10 e recuperação do último jogador ausente. As coordenadas dos dois jogadores continuam nos eventos `relay_coordinates` e `long_710_directional_b`. Adicionados `relay_lane_open_pass_queued` e `relay_pass_cancelled_blocker` em `csv/pass_auto_v06.csv`.

Limites de posse, geometria e tentativas permanecem. Projeção geométrica não garante deslocamento ou recepção. Necessária validação dinâmica no BizHawk.
