# PASS LV.1 v0.8.35 — aproximação diagonal 8 → 9 (UP+RIGHT)

Base da v0.8.34. A rota permanece 6→3→2→4→5→8→9→7→10→11, com prevenção de RIGHT antes de 6→3, pré-deslocamento de dois frames Down e Down+B em 4→5, preferência inicial RIGHT em 5→8 e monitor de gol pós-X inalterados.

**Somente na aproximação 8→9**, o controlador prioriza **Up e Right simultâneos**, em rajadas de até quatro frames direcionais, com pausa neutra e observação de distância e desvio lateral. Tenta no máximo três rajadas diagonais. Após cada uma, registra `approach_diagonal_feedback`; crescimento de distância >5 unidades ou crescimento >1 junto com lateral >5 desabilita a diagonal. Duas rajadas sem movimento geométrico detectável também desabilitam a diagonal. O controlador então volta à seleção calibrada das quatro direções individuais.

O evento `approach_diagonal_started` permite distinguir as rajadas realmente simultâneas, e `approach_motion_calibration` mantém as medidas de movimento do portador e receptor (a nova chave `Up_Right` é reconhecida). Não há B durante a aproximação; os guardas de bola/posse, os limites geométricos e teto 210 frames seguem ativos.

Limitação: o bloqueio é por regressão **entre rajadas**, não uma previsão de colisão; ainda requer teste no BizHawk. Comparar 8→9 com o mesmo savestate da execução v0.8.34.
