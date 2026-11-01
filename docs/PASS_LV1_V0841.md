# PASS LV.1 v0.8.41 — orientação UP antes de B, somente 6→3

Base exata da branch v0.8.40. Experimento de orientação apenas quando `origin==6` e `target==3`:

1. Aguarda o gate de posse já existente.
2. `pre_up`: dois frames de **UP isolado**, conferindo que o jogador 6 continua com a bola a até 18 unidades de seus pés.
3. `pre_up_release`: um frame **neutro**; a fase seguinte é diretamente `hold`, sem recalcular orientação ou executar alinhamento cardinal nessa preparação.
4. `hold`: **B isolado** durante a duração normal de três frames, sem RIGHT/LEFT/UP/DOWN; são preservadas as verificações do passe (`Feet.check` e `BallLine.check`) e o monitoramento de transferência/voo.

**Importante:** a exceção B sem direcional existe somente para o par 6→3. Outros passes continuam exigindo direcional no frame B. Os passes 6→2 (UP+B) e 4→5 (pré-Down, Down+B) não mudaram. As aproximações de 5→8 (até oito RIGHT e amostras neutras) e 8→9 (diagonal condicionada pelas coordenadas) permanecem na base sem modificações.

Logs específicos: `pre_up_step`, `pre_up_release`, `pass_direction_override`. Conferir ainda `pass_pulse`, `early_flight`, `receiver_mismatch` e receptor espacial. A validação real no BizHawk é necessária.
