# DRIBBLE Bot v0.3.2 — Persistent Score Validation

A v0.3.2 preserva a lógica de navegação/chute da v0.3.1. A nova confirmação é pós-tentativa e **não depende do script Lua continuar em execução**. A saída do gameplay permanece `unverified` até que um operador confirme explicitamente a tela de recorde da mesma tentativa.

## BizHawk

1. Encerre scripts anteriores e rode `git pull --ff-only origin main`.
2. Carregue `dribble_bot_v032.lua` no Lua Console.
3. Comece DRIBBLE LV.1 e mande `Add-Content .\dribble_bot_commands_v032.txt 'ARM'`.
4. Deixe concluir a tentativa. Após a saída do gameplay, o script grava o resumo quando completa a janela de observação; se precisar finalizar, `Add-Content .\dribble_bot_commands_v032.txt 'STOP'`.
5. Consulte as sessões com `Import-Csv .\dribble_bot_summary_v032.csv | Select-Object session,outcome,record_score | Format-Table -AutoSize`.

## Confirmar depois, inclusive com BizHawk fechado

**Somente se você viu o gol e o placar dessa tentativa**, copie o valor exato da coluna `session`:

```powershell
python .\confirm_dribble_score_v032.py --session "20261022T003522Z_1070377" --confirm-goal --score 403
```

A sessão acima é **apenas um exemplo** de formato; use o valor real da v0.3.2. O script rejeita sessões inexistentes ou repetidas e só altera a linha da sessão selecionada. Repetir a mesma confirmação é idempotente. Mudanças são auditadas em `dribble_bot_score_audit_v032.csv`. O script reescreve o resumo em arquivo temporário com substituição atômica; execute-o após o resumo ter sido gravado e enquanto não houver escrita concorrente do bot.

`CONFIRM_GOAL` e `SCORE:...` dentro do arquivo de comandos Lua não são utilizados para persistência na v0.3.2: use o comando Python. As durações em frames e os segundos BCD continuam sendo observações experimentais. Nenhum detector de gol em WRAM foi declarado validado.

## Arquivos

- `dribble_bot_trace_v032.csv`: telemetria da sessão identificada.
- `dribble_bot_summary_v032.csv`: uma linha por tentativa finalizada.
- `dribble_bot_score_audit_v032.csv`: trilha de alterações manuais.
- `dribble_bot_commands_v032.txt`: ARM/STOP.

Teste: `python -m unittest discover -s tests -p test_score_confirmation_v032.py`.
