# PASS LV.1 v0.8.80 — watchdog de neutralidade e coordenadas inválidas

Base v0.8.79.

## Travamento neutro 7→10
Monitora a ausência de controles efetivamente emitidos quando o estado indica `approach_neutral`. Após cinco frames neutros consecutivos, o watchdog limpa o estado de neutralização e a rajada anterior, para permitir recalcular a direção no ciclo seguinte. Registra `approach_710_neutral_watchdog`.

## Coordenadas WRAM inválidas
`Ordered.capture` recusa coordenadas não numéricas, NaN, com valores absolutos >=10000 ou (0,0) para portador/receptor. `Ordered.step` recusa movimento 7→10 baseado nesses dados. Um segundo guarda antes de `joypad.set` anula comandos quando a geometria do par está inválida, interrompendo após três leituras consecutivas e registrando `approach_710_invalid_coordinates`.

## Preservado
- Correção vertical 7→10 e extensões progressivas até teto de 480 frames para esse par.
- Teto de 210 para os demais, proteção bola–portador, passe condicionado à distância e repetição opcional 7→10 após visita.

## Verificação
Usar logs para conferir retomada após neutralidade, distância 7→10, ausência de comandos em geometria inválida. Casos em que os valores mudam para zero por transição devem ser tratados como desconhecidos, nunca conclusão de passe. Testes estáticos não substituem execução dinâmica no BizHawk.
