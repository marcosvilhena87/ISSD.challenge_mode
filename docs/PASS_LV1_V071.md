# PASS LV.1 v0.7.1 — diagnóstico de um único passe

O usuário observou que a versão anterior fazia **embaixadinhas** ao pressionar B repetidamente, sem deslocar-se nem passar. Esta versão substitui o controlador repetitivo por um experimento controlado.

- Após `PASSBTN:B`, `AUTO:ON`, `ARM`, identifica um portador espacial candidato e seleciona um receptor geométrico não visitado.
- Aciona **direcional e B simultaneamente por 3 frames** (valor fixo experimental).
- Em seguida solta todos os botões; aguarda até 90 frames por transferência espacial candidata.
- Registra deslocamento máximo da bola relativamente ao instante anterior ao comando.
- Classifica `transfer_candidate_observed`, `ball_moved_without_transfer` ou `no_ball_motion_detected`; **nunca repete** o passe sem novo ARM.
- Desativa a finalização com X nesta versão diagnóstica, mesmo se `FINISH:ON` for enviado.
- CSV: `csv/pass_auto_v06.csv` inclui `single_pass_result` e `max_ball_displacement` no motivo; os relatórios de posição e timers continuam.
- `AUTO:OFF` ou `STOP` soltam os botões e interrompem imediatamente.

O pulso direcional+B é apenas uma hipótese sobre a mecânica do ISSD. O deslocamento da bola isoladamente não prova que houve passe nem que o destino foi alcançado. Verifique visualmente o comportamento no BizHawk e compare com os CSVs.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v071_static.py" -v`.
