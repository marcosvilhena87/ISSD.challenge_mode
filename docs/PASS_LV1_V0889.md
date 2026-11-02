# PASS LV.1 v0.8.89 — desbloqueio do corredor 9→7

Base: v0.8.88.

Quando o jogador 9 tem a bola, o jogador 7 ainda não recebeu e uma terceira unidade obstrui geometricamente a faixa do passe, o controlador inicia um pequeno reposicionamento lateral do portador 9.

- Até **4 tentativas**, cada uma com **6 frames** de direção cardinal Up/Down alternada, sem Dash.
- Após cada deslocamento, observa posição inicial e final em WRAM, deltas X/Y e recalcula o corredor de 9 até 7 com `lane_blocker`.
- Se o corredor estiver livre e a posse/geometria permitirem, tenta **Control Pad + B simultâneos** por dois frames, através da rotina direcional já existente.
- Se a posse for perdida ou a geometria inválida, aborta o movimento.
- Se quatro reposicionamentos não abrirem o corredor, registra esgotamento e libera a aproximação normal existente; assim não bloqueia continuamente os comandos.

Eventos em `csv/pass_auto_v06.csv`: `relay_97_sidestep_started`, `relay_97_sidestep_finished`, `relay_97_sidestep_aborted`, `relay_97_sidestep_exhausted`, `relay_97_started`, `long_710_directional_b`, `long_710_receiver_observed`.

O novo algoritmo **não garante** recepção por 7 e pode precisar de novo experimento se o movimento lateral não modificar o corredor. A confirmação é apenas espacial até validação do estado oficial do desafio. Testes estruturais adicionados; execução real no BizHawk pendente.
