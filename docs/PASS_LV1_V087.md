# PASS LV.1 v0.8.7 — últimos passes perto do gol

A v0.8.7 conserva a sequência contínua da v0.8.6 e prioriza deixar os jogadores **11 e 10 para as duas últimas recepções**, preferencialmente 11 → 10.

## Algoritmo
- O portador inicial conta como um participante, inclusive se for 10 ou 11; o goleiro não conta.
- Enquanto houver jogadores não visitados entre **2 e 9**, a seleção por proximidade/alinhamento é restrita a esse grupo.
- Depois, caso o 11 ainda não tenha participado, tenta direcionar a bola a ele.
- Por último, quando o 11 já estiver visitado, tenta o 10.
- O alvo geométrico não garante o receptor efetivo; a sequência usa o histórico espacial real de candidatos e registra o resultado.
- Se o jogo encaminhar um passe a 10/11 antecipadamente, a lista de visitados prevalece; o bot não tenta repetir a participação.
- A cadeia termina ao identificar dez jogadores distintos, falhar numa transferência ou atingir o limite de 14 passes. **Sem chute automático.**

## Janela de recepção por distância inicial do passe
- Até 150 unidades: **90 frames**
- Acima de 150 até 300: **150 frames**
- Acima de 300: **210 frames**

O log `pass_auto_v06.csv` inclui `priority_stage` em `handoff_diagnostic` e `wait_frames` no evento `pass_pulse`.

## Executar
Reinicie `main.lua` na branch v0.8.7 e, com PASS LV.1 carregado, execute no PowerShell dentro do repositório:

```powershell
@(
 "PASSBTN:B"
 "DIRECTION:AUTO"
 "AUTO:ON"
 "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Valide visualmente as recepções, em especial os últimos jogadores, antes de habilitar o chute. O monitor espacial indica candidatos, não conclusões oficiais do jogo.
