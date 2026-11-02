# PASS LV.1 v0.9.5 — início pelo cronômetro de 30 segundos

Base v0.9.4. Com `AUTO:ON`, `FINISH:ON` e `ARM`, o controlador fica em espera; somente após uma leitura BCD do tempo principal **diminuir** (por exemplo 30→29) inicia a cadeia e ativa `autopass`. A leitura é feita pelo observador `pass_timers_v05` já utilizado no projeto. O evento `pass_clock_started` registra a mudança. Ativação continua opt-in: não há início automático sem ARM e AUTO:ON. É preciso armar antes da primeira redução para não perder o evento.

Quando o contador observado chega a zero, `pass_time_budget_expired` é emitido **uma vez** mesmo que o controlador tenha desativado a cadeia antes; se 10/10 não foi atingido, desativa a fase de passes. A finalização por bônus após 10/10 permanece separada.

O watchdog ativo da v0.9.4 foi mantido e registra `watchdog_active_blocked` a cada doze frames quando não entra em movimento por geometria ausente, bola distante ou tentativas esgotadas; logs de movimento e deslocamento também permanecem. O watchdog passivo fica condicionado a cronômetro iniciado e não expirado. As rotinas legadas ainda possuem timeouts específicos não todos expressos como segundos do jogo.

Validação pendente no BizHawk: confirmar ARM anterior a 30→29, `pass_clock_started`, movimentos e número de participações dentro do prazo. As observações 10/10 e conclusão do desafio são evidências espaciais, não validação oficial.
