# PASS LV.1 v0.8.38 — calibração de RIGHT com tolerância controlada

Base v0.8.37. Somente durante a aproximação **5→8**:
- Primeiros **quatro frames neutros** após reconhecimento da necessidade de aproximação, registrando X/Y dos jogadores 5 e 8 e ΔX/ΔY residual do 5 em `approach_right_settle`.
- RIGHT continua prioritário em **rajadas de dois frames**, sem alternância interna de botões. Cada frame de comando registra `approach_right_frame` com botões e coordenadas X/Y. O feedback continua na pausa neutra.
- Deslocamento **ligeiramente contrário** (por exemplo ΔX = -3) ou aumento modesto da distância é **tolerado**, registrado como `right_tolerated`. Não desativa RIGHT após uma única observação.
- O controlador continua interrompendo por regressão forte (>8 unidades de distância ou projeção horizontal <-6 por rajada), ou por regressão acumulada >12 após quatro amostras negativas; duas amostras imóveis também suspendem.
- A v0.8.37 permanece como mecanismo de isolamento: se RIGHT tiver bloqueio confirmado, emite `approach_right_blocked` e para, sem alternância silenciosa entre UP/LEFT.

Preservados 6→3→2, pré-Down e Down+B 4→5, diagonal UP+RIGHT em 8→9, limite de 210 frames e monitor pós-X. É um experimento diagnóstico; não presume que coordenadas negativas impliquem inversão definitiva do controle.
