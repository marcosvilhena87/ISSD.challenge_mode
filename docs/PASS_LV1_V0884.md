# PASS LV.1 v0.8.84 — passe longo 7→10 integrado na rota

Base: v0.8.80, sem a interceptação global dos experimentos v0.8.81–83.

Ao alcançar o jogador 7 como portador em uma rota que solicita 10, o controlador testa um passe longo se a distância inicial estiver entre 180 e 410 WRAM, a separação vertical for <=100 WRAM e a bola estiver a <=18 WRAM do portador. O limite 410 é experimental, não representa alcance garantido. Isso evita perseguir o receptor por centenas de frames nessas condições.

No ciclo de entrada, a rotina orienta 3 frames, libera por 2 frames e pressiona **Control Pad + B juntos** por 2 frames. Durante aproximadamente 120 frames observa, sem comandos adicionais do controlador de aproximação; caso haja posse observada do 10, registra `long_710_receiver_observed`, caso contrário `long_710_observation_timeout`. Depois libera o controle da rota para a lógica normal. Não reexecuta automaticamente o passe experimental na mesma sessão. Preserva a contagem oficial separada da evidência espacial.

Eventos em `csv/pass_auto_v06.csv`: `long_710_started`, `long_710_directional_b`, `long_710_receiver_observed`, `long_710_observation_timeout`, `long_710_aborted`.

A rotina de finalização X continua separada. A eficácia deve ser validada no BizHawk; os testes são estruturais e não confirmam sucesso no jogo.
