# PASS LV.1 v0.8.68 — execução real da antecipação 7→10

A v0.8.65 emitia `early_710_trial`, mas a rotina `Auto.step` voltava a exigir o limite convencional de alcance (`Feet.check`) antes do comando B. Assim o teste era autorizado sem executar o passe.

## Correção isolada
- `pass_bot.lua`: inclui `early_710_trial=true` no plano entregue ao Auto e registra `early_710_execution` durante seleção, gate de posse, orientação, soltura e B.
- `pass_auto_v071.lua`: só para o par 7→10 marcado experimentalmente, revalida a geometria de `pass_early_v0865.lua` antes do disparo e não aplica o limiar convencional de `Feet.check` ou a checagem de alinhamento destinada aos passes normais.
- A tentativa continua limitada a distância até 420 WRAM, lateral até 160 WRAM, bola aos pés e ao menos 24 frames prévios de aproximação no momento da autorização. O alinhamento é apenas hipótese experimental e não garante uma recepção.
- O comando B usa a máquina de estados existente: gate → direção sem B → frame neutro → direção+B. O log `early_710_execution` com `B=true` ou `pass_pulse` distingue autorização de execução real.
- Preservados 4→5 orientado, 6→7 UP+RIGHT, telemetria dos dois jogadores, referência do gol derivada do estádio, prova contextual pós-X e limite de aproximação.

## Verificação
`python -m unittest discover -s tests -p test_pass_v0868_static.py`. Comparar `early_710_trial` e `early_710_execution` com `pass_inputs_v081.csv`, `pass_auto_v06.csv`, `pass_reach_v0864.csv` e evento de transferência espacial. A simples emissão de B não comprova que o receptor 10 tenha recebido.

A validação dinâmica no BizHawk permanece pendente.
