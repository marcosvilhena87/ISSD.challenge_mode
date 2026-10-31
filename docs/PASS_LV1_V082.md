# PASS LV.1 v0.8.2 — Diagnóstico de destinatários e encerramento único

A v0.8.1 registrou repetidamente `no_valid_target`, sem emitir B. Esta revisão adiciona um diagnóstico estruturado dos candidatos e interrompe definitivamente o controle de passe após um resultado terminal.

## Telemetria

O arquivo `csv/pass_candidates_v082.csv` registra em cada tentativa de seleção: portador, motivo do seletor, total de jogadores, candidatos elegíveis, exclusões de portador, visitados e inválidos, além de identificador, ΔX, ΔY, distância, desalinhamento, custo e indicador de seleção de cada receptor.

O arquivo `csv/pass_auto_v06.csv` acrescenta o evento `target_rejected`, com motivo e contadores, quando o controlador recebe `no_valid_target`. `csv/pass_inputs_v081.csv` continua registrando os botões enviados a cada frame.

O resultado terminal interrompe o bot uma única vez por ARM; `AUTO:ON` e novo `ARM` são necessários para repetir o teste. A monitorização observacional permanece ativa até `STOP`.

## Teste no BizHawk

Abra PASS LV.1 e execute no PowerShell, na pasta do projeto:

```powershell
@(
 "PASSBTN:B"
 "DIRECTION:AUTO"
 "AUTO:ON"
 "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Confira se há nove receptores elegíveis quando o portador 6 for detectado, se `receiver_selected` é gravado e se `pass_inputs_v081.csv` contém três frames com B e direcional simultâneos. Nenhuma dessas condições é afirmada como validada no jogo.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v082_static.py" -v`.
