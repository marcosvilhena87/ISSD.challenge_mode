# PASS LV.1 v0.8.20 — sequência fixa e aproximação

Objetivo: tentar, na ordem, 6 → 2 → 3 → 4 → 5 → 8 → 9 → 7 → 10 → 11. A rota é estrita: não substitui o próximo receptor por outro jogador. Se uma recepção candidata chegar a jogador diferente do esperado, a cadeia é interrompida e registra route_deviation.

Enquanto o próximo receptor estiver fora dos limites geométricos em vigor, a automação tenta se aproximar do alvo. Cada intervenção usa **um frame direcional**, seguido de **um frame neutro**; no máximo 90 intervenções por transferência. A bola deve permanecer a até 18 unidades do portador; caso contrário, o bot interrompe sem B. A rota só é avançada após o monitor espacial identificar o destinatário esperado.

Após alcançar a distância e o desvio diagonal aceitos, o bot segue pelas barreiras existentes: posse estável, orientação, alinhamento A–bola–B e B direcional somente quando validado. Se a geometria piorar, a recuperação da v0.8.16 continua disponível.

Eventos de auditoria em csv/pass_auto_v06.csv: approach_step, approach_timeout, approach_aborted, route_advanced e route_deviation. Confira csv/pass_inputs_v081.csv para os frames individuais de aproximação. Até a validação no BizHawk, os sinais de posse e conclusão continuam candidatos, não vitória oficial.

Comandos depois de reiniciar main.lua:

    @("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","AUTO:ON","ARM") |
      Add-Content ".\\txt\\pass_bot_commands_v01.txt"

Use FINISH:ON antes de ARM se quiser habilitar X ao confirmar 10/10 e o bônus. 
