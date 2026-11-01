# PASS LV.1 v0.8.29 — feedback multidimensional + passe 6→2 com UP+B

Base: v0.8.28. A v0.8.28 parou prematuramente em 2→4 porque o custo geométrico ponderado podia subir mesmo com melhora da distância, e rajadas sem deslocamento detectável eram punidas imediatamente.

## Aproximação

Em cada pausa neutra, compara distância e desvio lateral observados no começo e fim da rajada. Se **qualquer uma** das duas medidas cair mais de 0,5, classifica progresso parcial e não acumula rajada ruim, mesmo quando a outra piorar. Se **ambas** piorarem mais de 0,5, penaliza a direção e aumenta o contador de rajadas ruins. Nas demais situações, aguarda até três leituras equivalentes antes de penalizar, reconhecendo latência/ausência de deslocamento observável. O limite de oito rajadas ruins permanece como proteção. Mantém rajadas de até quatro frames, limite inicial 90, extensões condicionais até 210, verificações da bola e da geometria.

Novos resultados no evento `approach_direction_feedback`: `direction_partial_progress`, `direction_pending_feedback`, `direction_worsened` e `direction_no_progress`, com `distance_gain` e `lateral_gain`.

## Direção específica

Quando o passador real é jogador **6** e o destinatário selecionado é jogador **2**, `autopass.direction="Up"`, mantendo o botão `B` já executado pelo estado de envio. Portanto, no frame de chute desse par, o controle envia **Up+B**. O evento `pass_direction_override` identifica o caso. Para todos os demais pares permanece `DIRECTION:AUTO` (ou seleção do operador), evitando alterar o restante da cadeia.

A substituição é uma hipótese experimental indicada pelo operador, ainda não validada por amostras controladas. Os registros `transfer_candidate_observed` são espaciais, não confirmação oficial do objetivo.

## Validação

Reinicie `main.lua` no BizHawk após trocar de branch. Reproduza com `TRIGGER:A`, `CALIB:A`, `PASSBTN:B`, `DIRECTION:AUTO`, `FINISH:ON`, `AUTO:ON`, `ARM`. Compare o mesmo savestate com a v0.8.28. Confira `pass_direction_override`, `pass_inputs_v081.csv`, `approach_direction_feedback`, cobertura 10/10 e, se houver X, `pass_goal_evidence_v0826.csv`.

Testes estruturais incluídos, sem execução no BizHawk nesta sessão.
