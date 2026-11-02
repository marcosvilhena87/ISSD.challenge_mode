# PASS LV.1 v0.8.70 — aproximação curta 7→10

Base: v0.8.69. A sessão 20261102T001438Z mostrou distância inicial 7→10 de 433,37 WRAM; tentativa antecipada começou em ~415,53, mas orientação elevou para 435,46 e bloqueou o comando B. A mediana dos 9 planos anteriores foi 153,45 WRAM.

## Alteração
- Referência: 160 WRAM; liberação de passe apenas até 180 WRAM e erro lateral até 100.
- A trava vale tanto para a seleção normal quanto para o passe antecipado 7→10. O plano normal mais longo que o limiar volta para a lógica de aproximação, não para B.
- O controlador de aproximação e seu teto absoluto de 210 frames permanecem; não aumenta o teto, não modifica outras duplas.
- A nova telemetria `approach_710_close_gate` registra distância, lateral e razão do bloqueio. O evento `early_710_trial` registra também `target_distance`.
- Não garante alcançar 160: quando chegar à faixa segura até 180, o passe poderá ocorrer. Caso 210 frames se esgotem, parar com segurança sem forçar B. Preservar verificação do posse e limites de orientação existentes.

## Validar no BizHawk
1. Carregar esta branch, reiniciar Lua, executar AUTO:ON e ARM.
2. Examinar `csv/pass_auto_v06.csv`, especialmente `approach_710_close_gate`, `early_710_trial`, `early_710_execution` e `approach_aborted`.
3. Confirmar empiricamente que B é liberado somente com distância <=180 e lateral <=100 no quadro de seleção, que o deslocamento é progressivo e que não ocorre aproximação cega após atingir o teto absoluto.
4. Comparar receptor real com planejado usando `csv/pass_reach_v0864.csv`. A confirmação final do desafio ainda depende de observação no jogo.
