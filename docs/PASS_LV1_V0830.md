# PASS LV.1 v0.8.30 — calibração dinâmica de movimento

Base: v0.8.29. O controle captura coordenadas do portador e do receptor antes de cada rajada de aproximação (até quatro frames direcionais) e novamente no frame neutro seguinte. O movimento relativo é decomposto em deslocamento do portador (holder_dx/dy) e do receptor (receiver_dx/dy), evitando atribuir à entrada direcional deslocamentos causados apenas pelo receptor. Quando há movimento mensurável, o controlador aprende um vetor médio por direção e usa esse vetor para estimar custo geométrico na seleção de ações; se o deslocamento observado do portador contrariar a direção esperada, aumenta a penalidade. Se não houver deslocamento perceptível, marca motion_delayed_or_still sem aprender vetor espúrio.

O evento `approach_motion_calibration` no `csv/pass_auto_v06.csv` inclui direção, os dois deslocamentos e projeção do portador na direção comandada. A correção por feedback de distância/lateral continua ativa.

Passes específicos: **6→2** usa `Up+B` e **4→5** usa `Down+B`, apenas quando esses são os pares efetivamente selecionados; os demais seguem direção automática ou definida pelo operador. O evento `pass_direction_override` identifica cada substituição. A direção configurada para outros passes não é alterada.

Preservados: limites de aproximação inicial 90 e absoluto 210, extensão condicional, rota adaptativa, fluidez de rajadas e monitor de gols pós-X da v0.8.26.

Verificar primeiro com um savestate fixo e examinar `pass_inputs_v081.csv`, `pass_direction_v072.csv`, `pass_auto_v06.csv` e, após X, `pass_goal_evidence_v0826.csv`. Código não testado no BizHawk.
