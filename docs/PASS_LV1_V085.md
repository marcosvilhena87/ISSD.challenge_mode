# PASS LV.1 v0.8.5 — aguardar portador estável

A v0.8.4 desabilitava a automação após detectar `no_stable_holder` antes de o monitor espacial estabilizar o jogador 6. A v0.8.5 altera **somente o portão de espera do portador**.

- Enquanto `autopass.phase == "idle"` e `spatial.holder == nil`, não chama a ponte nem `Auto.step()`; mantém `autopass.enabled=true` e deixa `joypad.set({})`.
- Assim que o monitor informar um portador estável, permite a seleção e a tentativa única de passe já existente.
- Se não houver portador após **180 frames contados do ARM**, registra uma única vez `holder_detection_timeout` e desativa a tentativa.
- Em `align`, `hold` ou `wait`, a lógica já iniciada não depende da presença momentânea do portador.
- Mantém diagnóstico de portas da v0.8.4. **Sem alterações** no seletor geométrico, na temporização de B ou no chute final.

## Teste

Reinicie `main.lua` na branch v0.8.5 e, no diretório do repositório, execute no PowerShell:

```powershell
@(
 "PASSBTN:B"
 "DIRECTION:AUTO"
 "AUTO:ON"
 "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Verifique se `csv/pass_runtime_gates_v084.csv` registra `no_stable_holder` seguido de `ready`, e se `csv/pass_auto_v06.csv` contém `receiver_selected` e `pass_pulse`. A recepção real ainda requer confirmação no BizHawk.
