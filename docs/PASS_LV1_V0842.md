# PASS LV.1 v0.8.42 — orientação versus execução do passe

**Regra operacional:** Control Pad isolado (por exemplo `Up=true`, sem `B`) serve para **orientar** o jogador. Control Pad **junto com B**, no mesmo frame, serve para **executar o passe**.

Somente no par **6 → 3**, após confirmação de posse:
1. Pressionar **UP isolado por dois frames** (`pre_up_step`).
2. Soltar todos os botões durante **um frame** (`pre_up_release`).
3. Pressionar **UP+B por três frames** (`direction_and_B_hold`, `pass_pulse`).

Não executar alinhamento automático entre a preparação e UP+B: erros `ball_behind_carrier` e `ball_off_pass_axis` são tolerados exclusivamente na checagem BallLine desse experimento, mas ainda exigem bola a até 18 unidades dos pés e `Feet.check` válido. Falhas de posse, distanciamento e demais critérios de segurança permanecem impeditivos.

**Escopo restrito:** 6 → 2 continua UP+B; 4 → 5 continua pré-Down e Down+B; 5 → 8 continua com RIGHT de até oito frames e amostras neutras; 8 → 9 continua condicionado à geometria. Não são alteradas as outras rotas ou os limites de aproximação.

**Validação:** Examinar `pre_up_step` duas vezes, `pre_up_release` uma vez e três frames com `Up=true` e `B=true`; conferir também `early_flight` e o receptor espacial. O resultado precisa ser testado no BizHawk.
