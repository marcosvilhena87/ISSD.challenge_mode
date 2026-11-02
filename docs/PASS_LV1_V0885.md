# PASS LV.1 v0.8.85 — passe 7→10 e resgate do último jogador

Base: v0.8.84. A lógica do passe direcional continua exigindo **Control Pad + B simultâneos**.

## Recuperação do jogador ausente
Ao constatar exatamente **um jogador de linha não visitado (IDs 2..11)**, calcula sua geometria relativa ao portador atual e o prioriza como alvo do pulso B direcional. Não adiciona visitas por intenção: a recepção deve ser confirmada pelos eventos espaciais já existentes. Não há garantia física de recepção; situações sem geometria, com corredor bloqueado, distância >410 WRAM ou separação vertical >100 WRAM continuam fora do pulso automático.

## Proteção do corredor
Antes de um passe experimental, inspeciona as posições das outras unidades observadas e rejeita o lançamento quando uma delas fica na região central (10–90%) do segmento portador–alvo, a até 24 WRAM da linha. Registra `long_pass_lane_blocked` sem declarar que a recepção teria falhado. Essa checagem é aproximada, sem previsão dinâmica de interceptação.

## Execução
A tentativa longa pode começar imediatamente quando o jogador 7 tem posse, 10 é o próximo destino efetivo e a geometria satisfaz os limites, ou quando resta um único jogador ausente. O trecho habitual de orientação é 3 frames, neutro 2 frames, direção+B 2 frames, seguido de observação de até 120 frames. Após sucesso espacial ou expiração, o controlador devolve o fluxo à rota normal, sem declarar sucesso oficial do jogo.

Eventos `csv/pass_auto_v06.csv`: `long_710_started` com `kind=last_missing` ou `kind=relay_710`, `long_pass_lane_blocked`, `long_710_directional_b`, `long_710_receiver_observed`, `long_710_observation_timeout`.

**Limitação:** se o passe for bloqueado ou falhar, a rota normal pode ainda necessitar de aproximação ou novas tentativas em sessões posteriores. Esta versão aumenta a prioridade do jogador ausente, não garante matematicamente o passe. Testes estruturais não substituem a execução BizHawk.
