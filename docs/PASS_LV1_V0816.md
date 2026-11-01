# PASS v0.8.16 - Replanejamento seguro
A v0.8.16 trata a rejeição geométrica anterior ao B: solta os botões por três frames, exclui o último alvo rejeitado e reavalia os companheiros nas coordenadas atuais. Repete no máximo três vezes por tentativa de passe; o contador é zerado após transferência observada. Se não houver alternativa elegível, encerra sem passe especulativo.

Mantém distância limite de 190, diagonal secundária limite de 72 e alteração do vetor de no máximo 32 por eixo. Cada novo receptor passa novamente pela estabilidade espacial de posse e pela orientação direcional. A recuperação não se aplica a passes que já partiram do pé e terminaram sem recepção.

Auditoria: csv/pass_auto_v06.csv registra retarget_requested, retarget_ready e retarget_limit_stop; csv/pass_inputs_v081.csv permite verificar ausência de B durante a recuperação.

Exemplo de comandos após reiniciar main.lua:

    @("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","FINISH:ON","AUTO:ON","ARM") |
      Add-Content ".\txt\pass_bot_commands_v01.txt"

A validação prática no BizHawk permanece pendente.
