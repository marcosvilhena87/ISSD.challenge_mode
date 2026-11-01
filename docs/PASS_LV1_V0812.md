# PASS LV.1 v0.8.12 — estabilidade de posse e REARM

A v0.8.12 preserva a estratégia de passes de apoio e o diagnóstico TRIGGER:A/B, acrescentando uma barreira de **estabilidade espacial** antes do passe.

## Barreira de estabilidade
- O controlador verifica a distância entre bola e portador espacial a cada frame, **sem enviar botões**.
- Exige 4 leituras consecutivas do mesmo jogador com distância até 18 unidades e variação de distância de até 3 unidades entre leituras.
- Se não obtiver estabilidade em 120 frames, encerra com `possession_gate_timeout` sem pressionar B.
- A estabilidade de proximidade **não comprova** posse real da ROM. É um filtro experimental contra acionamento prematuro.
- Depois da barreira, TRIGGER:A prossegue imediatamente ao alinhamento; TRIGGER:B acrescenta 12 frames neutros antes do alinhamento.
- Mantém 3 frames de direcional + B simultâneos, sem reenvio no mesmo passe.

## REARM
Após uma tentativa encerrada, `REARM` reinicia a cadeia dentro do mesmo processo Lua, desde que ainda esteja armado e `PASSBTN:B` esteja configurado. O comando exige ação explícita do operador; não há rearmamento automático. Um REARM reinicializa monitor e conjunto de participantes e não deve ser confundido com uma continuação do mesmo desafio já em andamento. Para teste A/B rigoroso, recarregue o **mesmo savestate** e reinicie `main.lua`.

## Auditoria
`csv/pass_trigger_v0811.csv` registra também a fase `possession_gate`, com posição da bola, portador espacial e botões enviados. `csv/pass_auto_v06.csv` registra `possession_gate_ready` e `possession_gate_timeout`.

## Comandos PowerShell
No diretório do projeto, depois de reiniciar `main.lua` no PASS LV.1:

```powershell
@("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","AUTO:ON","ARM") |
 Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Para uma nova tentativa após falha terminal (sem mudar de modo):

```powershell
Add-Content ".\\txt\\pass_bot_commands_v01.txt" -Value "REARM"
```

O chute automático continua desativado. A confirmação oficial do desafio requer validação no jogo.
