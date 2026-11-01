# PASS LV.1 v0.8.31 — recuperação de estagnação e prevenção de interposição 6→3→2

Base v0.8.30. Quando a aproximação não pode ser estendida ou completa oito rajadas ruins, tenta uma **única** recuperação de até 16 frames direcionais adicionais (respeitando o teto total absoluto de 210). Seleciona o vetor aprendido que projeta a maior melhoria de custo geométrico; sem vetor com melhora projetada, encerra sem insistir. Conserva controles por rajadas fluidas de quatro frames, amostras neutras e segurança de geometria/bola.

Para o primeiro par 6→2, a hipótese do operador é que RIGHT desloca 6 para a interposição de 3. O bot não escolhe RIGHT como aproximação nesse par, não o utiliza na recuperação e suprime RIGHT isolado antes do passe. A regra UP+B continua no acionamento do passe 6→2; Down+B continua em 4→5. A cada dez frames relevantes, registra `interposition_6_3_2` com posição relativa de 3 ao segmento 6–2 (projeção e offset), usando limiar heurístico lateral 30; isso NÃO comprova trajetória nem colisão interna.

A telemetria `approach_recovery_started`, `approach_no_improvement`, `approach_timeout` e `interposition_right_suppressed` é registrada em `csv/pass_auto_v06.csv`. O monitor pós-X da v0.8.26 continua intacto.

Validação em BizHawk pendente. Repetir com o mesmo savestate e comparar posicionamento de 3, receptor do passe 6→2, recuperações, cobertura total e resultado após X.
