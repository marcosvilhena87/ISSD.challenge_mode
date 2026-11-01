# PASS LV.1 v0.8.34 — extensão por progresso recente e pré-deslocamento Down

Base v0.8.33. Mantém a rota padrão 6→3→2→4→5→8→9→7→10→11 e bloqueio RIGHT durante a preparação 6→3.

## Aproximação
O observador registra a sequência de amostras neutras com redução de distância >0,5. Duas amostras consecutivas de melhora permitem extensão de +30 frames, limitada a duas concessões **por progresso recente** por aproximação, respeitando o teto absoluto de 210 frames. Ainda exige não estar estagnado e que a distância atual não tenha regredido mais de 12 em relação à melhor. Fora disso permanecem as condições anteriores de progresso líquido de 12 unidades. O evento `approach_recent_progress` identifica o trecho 5→8 com melhora consecutiva; `approach_extended` identifica o motivo `recent_progress_verified`.

## Passe 4→5
Após a estabilização da posse e antes da orientação normal, aplica **dois frames Down sem B**, em seguida um frame neutro (`pre_down_release`). O estado normal volta a orientar e então envia **Down+B** nos três frames de passe, como anteriormente. O movimento preparatório não é aplicado a outros pares. A cada frame Down, revalida que o portador é 4 e que a bola continua a ≤18 unidades de seus pés. O verificador geométrico e o alinhamento bola–portador–destino continuam no instante do passe. Eventos `pre_down_step` e `pre_down_release` no CSV.

O pré-deslocamento pode modificar a geometria e precisa de avaliação experimental; seu sucesso não é presumido. Preserva proteção de aproximação, recuperação exploratória e monitor de evidências de gol pós-X da v0.8.26. Validar no BizHawk usando o mesmo savestate.
