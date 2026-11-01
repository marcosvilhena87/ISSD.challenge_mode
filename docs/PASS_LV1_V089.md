# PASS LV.1 v0.8.9 — planejamento por coordenadas

A v0.8.9 aprimora a ordem de passe usando as coordenadas WRAM **x/y dos dez jogadores de linha**, mantendo as demais garantias da v0.8.8.

## Estratégia
- O portador inicial conta como participante.
- Enquanto ainda houver algum jogador 2–9 pendente, 11 e 10 não são selecionados intencionalmente. Preferência final: **11 e depois 10**.
- Para cada próximo receptor elegível, o planejador calcula o **custo imediato** (distância euclidiana mais penalidade de desalinhamento) e o **custo futuro aproximado** dos jogadores ainda não visitados, seguindo uma rota gulosa a partir daquele receptor e terminando em 11 → 10 quando ainda pendentes.
- Seleciona o receptor com menor soma estimada. Em empates, prioriza o menor custo imediato e depois o menor ID.
- Recalcula após cada recepção espacial observada. Os alvos não são garantidos: o jogo pode direcionar a bola a um jogador diferente.
- O histórico de visitados usado na projeção é o *real*, não a máscara temporária de destinatários excluídos; isso permite que 11 e 10 influenciem o custo final, embora permaneçam reservados.

## Telemetria
No `csv/pass_auto_v06.csv`, o evento `handoff_diagnostic` inclui `route_score` e `route_version=0.8.9`. Cada `route_candidate` registra `rank`, `immediate`, `onward`, `total` e `stage`.

## Garantias
Não altera tempo de pulso B, janelas adaptativas/espera adicional da v0.8.8, contagem de participantes, limite da cadeia ou chute final (X continua desativado). Não escreve na RAM.

## Executar
Reinicie `main.lua` com a branch v0.8.9, entre em PASS LV.1 e execute no PowerShell:

```powershell
@(
 "PASSBTN:B"
 "DIRECTION:AUTO"
 "AUTO:ON"
 "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Comparar o número de transferências e o percurso de 10/10 com a v0.8.8. Esta estimativa geométrica não comprova sucesso oficial nem garante a identidade do receptor; validar no BizHawk.
