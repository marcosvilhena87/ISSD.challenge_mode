# v0.8.18 — procurar alinhamento A–bola–B

A v0.8.17 rejeitava alvos sem alinhamento já na seleção. Esta versão deixa o seletor escolher um receptor que satisfaça as restrições de distância e ângulo, mesmo que o teste A–bola–B esteja desalinhado. Antes de B, o controlador tenta corrigir a posição com até **dois frames direcionais**, reavaliando a geometria após cada frame. Se conseguir, inicia o passe. Caso contrário, libera botões e aciona o replanejamento da v0.8.16, com limite de três rejeições por tentativa.

O filtro ainda exige bola próxima a A. Se ela estiver longe, **não há tentativa de condução cega**: troca de alvo ou para. Os movimentos corretivos são hipóteses geométricas não calibradas para o jogo; podem não melhorar o alinhamento e, nesse caso, devem abortar.

Auditoria: `pass_auto_v06.csv` registra `active_alignment_started`, `alignment_adjust_*`, `active_alignment_ready`, `retarget_requested_*`. Comparar `pass_inputs_v081.csv` e `pass_trigger_v0811.csv` para confirmar ausência de B durante correção.

Para ativar o modo padrão após reiniciar main.lua:

```powershell
@("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","AUTO:ON","ARM") |
 Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

O chute com X segue opcional via FINISH:ON antes do ARM. Requer validação no BizHawk e teste com mesmo savestate.
