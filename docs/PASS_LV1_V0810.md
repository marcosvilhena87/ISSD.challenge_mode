# PASS LV.1 v0.8.10 — passes de apoio opcionais

O bot pode usar **jogadores já visitados** como intermediários quando isso reduzir o custo estimado de um passe longo. O portador inicial já participa. A seleção tenta visitar todos os jogadores 2–9 antes de escolher 11 e, por último, 10.

## Penalizações e limites
- Custo geométrico = distância + 0,25 × desalinhamento além da tolerância de 12 unidades.
- Passe direto para jogador novo: custo geométrico, acrescido de 2 × (custo − 180) quando o passe for longo.
- Passe via jogador já visitado: primeira perna + menor segunda perna até um jogador novo + **penalidade fixa 100**; ambas as pernas estimadas devem ter até 200 unidades.
- Não escolhe o portador atual, o receptor imediatamente anterior nem jogadores 10/11 para apoio. Máximo de **dois apoios consecutivos** estimados a partir dos receptores efetivamente observados.
- Mantém 11 e 10 como último e penúltimo **preferenciais**, sem garantia de destinatário real.
- Limite de segurança experimental: **18 transferências** por ARM, incluindo apoios. A detecção é espacial e não garante reconhecimento oficial.
- Sem escrita de RAM e sem chute automático.

## Auditoria
O log `csv/pass_auto_v06.csv` registra `relay_mode` em `handoff_diagnostic` e `relay_outcome` após a detecção do receptor real. Continuam os eventos de voo e janela estendida da v0.8.8.

## Execução
Reinicie `main.lua` nesta branch, entre em PASS LV.1 e execute no PowerShell:

```powershell
@(
 "PASSBTN:B"
 "DIRECTION:AUTO"
 "AUTO:ON"
 "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Comparar jogadores distintos por passe, apoios utilizados e término com 11 → 10 contra a v0.8.8. Esta implementação é experimental e necessita validação no BizHawk.
