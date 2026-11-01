# PASS LV.1 v0.8.37 — garantir RIGHT real e calibração coerente

Motivo: a v0.8.36 suspendia RIGHT após detectar regressão e passava a tentar UP e LEFT. Além disso, durante as rajadas de até quatro frames, `Ordered.step` era chamado novamente e o botão selecionado podia mudar antes da amostragem, gerando observações atribuídas à direção inicial apesar de combinações físicas inconsistentes.

**Comportamento corrigido:** durante a aproximação 5→8, RIGHT continua prioritário enquanto o feedback não demonstrar bloqueio; rajadas RIGHT têm **até dois frames**, seguidas de um frame neutro e medição real. Durante qualquer rajada o código revalida a segurança/posse a cada frame, mas mantém os mesmos botões selecionados no início. Em 5→8, caso o deslocamento medido esteja no sentido contrário, aumente significativamente a distância ou permaneça imóvel de forma recorrente, a automação para com o evento `approach_right_blocked`; **não troca silenciosamente por UP ou LEFT**.

O bloqueio é um diagnóstico de incompatibilidade entre comando e deslocamento medido, não uma correção comprovada da entrada do emulador. Se ocorrer, comparar `pass_input`, `approach_motion_calibration`, estado de posse e visualmente o movimento no BizHawk antes de novas mudanças. A regra diagonal 8→9 UP+RIGHT, os dois frames Down antes de Down+B em 4→5 e o teto de 210 frames são preservados.

Requer teste real no BizHawk.
