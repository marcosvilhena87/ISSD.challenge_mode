# PASS LV.1 v0.8.46 — predição curta do receptor 9

Base: v0.8.45. Mudanças exclusivamente na aproximação 8→9.

- Em fronteiras neutras de movimento, registrar X/Y do receptor 9 e a diferença com a última amostra (`approach_89_neutral_velocity`). A velocidade estimada usa Δposição/Δframes e suavização por média com a estimativa anterior.
- Descartar velocidade implausível (>12 unidades WRAM por frame em qualquer eixo) e amostras muito espaçadas (>12 frames).
- Prever a posição até **4 frames** no futuro, limitando o deslocamento extrapolado em **±24 unidades por eixo**. Dados de velocidade ficam inválidos após 12 frames sem amostra nova.
- O controlador de direção 8→9 usa a previsão somente para selecionar o comando; a validação de posse, Feet.check, distância mínima e medições de progresso usam **posições reais atuais**.
- Logs `approach_89_predicted_target` mostram previsão, deslocamentos e horizonte. Sem previsão confiável, volta à geometria atual.
- Mantidas parada de regressão relativa 8→9, separação mínima global 24, UP → neutro → UP+B em 6→3, pré-Down + Down+B em 4→5 e RIGHT prolongado em 5→8.

A estimativa é experimental e não representa leitura de intenção do jogador 9. Exige validação no BizHawk.
