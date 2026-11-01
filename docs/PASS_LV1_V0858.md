# PASS LV.1 v0.8.58 — progresso líquido em 7→10

Base: branch v0.8.57. O controle de passes, a prioridade 9→7, a alternativa 6→7 e o monitor pós-chute baseado no DRIBBLE permanecem intactos.

A versão anterior podia conceder extensões por movimento do jogador 7 mesmo quando o jogador 10 se afastava mais depressa. Agora o feedback de 7→10 separa:
- `carrier_toward`: movimento do jogador 7 na direção do receptor;
- `receiver_away`: afastamento projetado do jogador 10;
- `net_gain_burst`: redução da distância de uma rajada;
- `net_gain_recent`: soma das quatro últimas reduções (valores negativos indicam regressão).

Para ativar a extensão especial `pair_710_recent_right_progress`, são necessários **dois RIGHT produtivos**, `carrier_toward>0,5`, ganho líquido recente >=8 e distância atual não superior à melhor distância histórica +12 unidades. Checkpoints goalward também exigem distância atual próxima à melhor registrada, além dos 25 de progresso por etapa. Extensões continuam limitadas e o teto absoluto permanece **210 frames**.

Novo evento: `approach_710_net_progress` nos CSVs de telemetria já existentes. Resultados espaciais continuam não oficiais. O monitor de gol da v0.8.57 ainda depende de um novo X e de 300 frames pós-chute.

Testes estruturais: `python -m unittest discover -s tests -p test_pass_v0858_static.py`. Necessário executar no BizHawk para medir resultado.
