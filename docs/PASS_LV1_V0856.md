# PASS LV.1 v0.8.56 — acompanhamento 7→10 com receptor avançando em direção ao gol

Base: v0.8.55. Hipótese do experimento: o jogador 10 afasta-se do jogador 7 porque continua avançando em direção ao gol. Deslocamento horizontal positivo do receptor é registrado como `receiver_goalward_candidate` e **não é prova** da intenção, da posição exata do gol ou de que o comando possa alcançar o alvo.

**Aproximação em etapas:** o controlador pode reconhecer até **dois checkpoints** específicos para 7→10 quando há pelo menos duas rajadas RIGHT produtivas, avanço do portador comprovado >0,5 e redução de pelo menos 25 unidades desde o checkpoint anterior (ou distância inicial). Cada checkpoint permite avançar o prazo local por 30 frames, sempre respeitando o limite global existente **MAX_APPROACH_ABSOLUTE=210**. Não reinicia o contador absoluto nem antecipa passes que não atendam a geometria.

**Telemetria:** `approach_710_goalward_feedback` registra deslocamento do receptor no eixo X, sinalização da hipótese de avanço rumo ao gol, deslocamento relativo e distância. `approach_710_goalward_checkpoint` registra estágio e distância. A auditoria `approach_target_joypad_commit` registra os botões na saída para `joypad.set` com o alvo ativo armazenado na decisão (`movement.target`), em vez de depender apenas de `autopass.target` (que pode não refletir a aproximação).

**Rota:** 9→7 continua principal, 6→7 alternativa se houver retorno de posse ao 6; depois prosseguir a 7→10→11. Mantidas regras de posse, limites de distância mínima global, controles de regressão e confirmação oficial pendente. Testes estruturais inclusos; execução real BizHawk necessária.
