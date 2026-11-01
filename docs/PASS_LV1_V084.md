# PASS LV.1 v0.8.4 — diagnóstico de portas de execução

A versão 0.8.3 passou no autoteste Lua, mas uma sessão real não registrou receptor ou pulso. A v0.8.4 instrumenta as condições do laço principal para distinguir automação desabilitada, falta de amostra WRAM, ausência de portador estável e conclusão anterior.

## Novo arquivo

`csv/pass_runtime_gates_v084.csv` traz `session,frame,gate,armed,enabled,finished,has_sample,holder,phase,probe_status,reason`.

Os eventos são **gravados somente quando a assinatura do estado muda**, evitando escrita de uma linha a cada frame. Os motivos incluem `not_armed`, `auto_disabled`, `already_finished`, `missing_spatial_sample`, `integration_selftest_failed`, `no_stable_holder` e `ready`.

Também corrige a mensagem `receiver_selected`: a ponte v0.8.3 retorna `id` e `aligned`; distância, desalinhamento e custo agora são recuperados de `report.candidates` antes da formatação, em vez de acessar campos ausentes.

## Teste PowerShell

No diretório do projeto, com `main.lua` reiniciado em PASS LV.1:

```powershell
@(
  "PASSBTN:B"
  "DIRECTION:AUTO"
  "AUTO:ON"
  "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Inspecione `pass_runtime_gates_v084.csv`, `pass_auto_v06.csv`, `pass_candidates_v082.csv` e `pass_inputs_v081.csv`. Continua um passe por ARM, sem disparo X automático ou escrita de RAM. O autoteste Lua no boot não substitui validação no BizHawk.
