# PASS LV.1 v0.8.6 — cadeia contínua de dez jogadores

Esta versão substitui a parada após a primeira transferência candidata por uma sequência de tentativas de passe. Um único conjunto de comandos `PASSBTN:B`, `DIRECTION:AUTO`, `AUTO:ON`, `ARM` habilita a cadeia experimental.

## Regras

- Após o primeiro `spatial_initial_candidate`, marca o portador inicial como um dos **dez jogadores de linha** visitados. O goleiro (1) não conta.
- Escolhe o receptor elegível mais próximo, excluindo IDs já visitados, com a mesma penalidade de desalinhamento da v0.8.5.
- Cada tentativa contém até dois frames de correção, três frames de **Control Pad + B simultâneos**, espera de até 90 frames e detecção espacial do novo portador.
- Ao detectar `transfer_candidate_observed`, registra a recepção candidata, preserva o conjunto `spatial.visited`, espera oito frames e reinicia **apenas o atuador** para o passe seguinte.
- Para ao atingir dez IDs de linha distintos, ou após 14 transferências candidatas (limite), ou no primeiro erro/timeout da tentativa. Se a bola se mover sem recepção espacial, não repete B indiscriminadamente.
- `STOP` e `AUTO:OFF` cancelam a cadeia. O chute com X permanece desligado.

## Telemetria

`csv/pass_auto_v06.csv` contém novos eventos `chain_initial_player`, `chain_transfer_candidate`, `chain_next_pending`, `chain_complete_candidate`, `chain_limit_stop`.

`csv/pass_spatial_v04.csv` contém transferências candidatas e total de distintos visitados, mas **não comprova** validação oficial pelo desafio. `csv/pass_inputs_v081.csv` registra o direcional + B solicitado à API do BizHawk.

## Executar

Reinicie `main.lua` na branch v0.8.6, entre em PASS LV.1 e, no PowerShell dentro do repositório:

```powershell
@(
  "PASSBTN:B"
  "DIRECTION:AUTO"
  "AUTO:ON"
  "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Verifique visualmente as trocas. Se houver passes que não alcancem o jogador planejado, o bot registra o receptor observado e seleciona um novo não visitado a partir dele. **Não há garantia de completar os dez**: o modelo de destinatários é geométrico e o monitor é inferencial; erros devem encerrar com segurança.
