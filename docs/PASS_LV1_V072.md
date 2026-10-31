# PASS LV.1 v0.7.2 — calibração direcional por passe único

A v0.7.1 confirmou visualmente que direcional+B por 3 frames gera passes, mas o receptor planejado (jogador 2) diferiu do candidato observado (jogador 3). A v0.7.2 permite testar a direção sem repetir o passe automaticamente.

## Preparação no BizHawk

Inicie `main.lua` no modo PASS, entre no PASS LV.1 e acrescente uma linha por comando a `txt/pass_bot_commands_v01.txt`:

```text
PASSBTN:B
DIRECTION:RIGHT
AUTO:ON
ARM
```

Valores de `DIRECTION`: `AUTO` (geometria relativa, padrão), `NEUTRAL`, `UP`, `DOWN`, `LEFT`, `RIGHT`, `UP_LEFT`, `UP_RIGHT`, `DOWN_LEFT`, `DOWN_RIGHT`.

**Uma única tentativa por ARM:** o controlador mantém B + direcionais por 3 frames, solta e aguarda até 90 frames. Requer um novo `AUTO:ON` e `ARM` para outro teste. `AUTO:OFF` e `STOP` interrompem a emissão de botões. Finalização com X desabilitada nesta etapa de calibração.

## Evidências

`csv/pass_direction_v072.csv`: sessão, frame, resultado, origem, destino geométrico planejado, receptor espacial candidato observado, direção aplicada, deslocamento máximo da bola, frame de pulso, frame de transferência e latência em frames.

`csv/pass_auto_v06.csv` continua registrando os eventos de tentativa. Se o jogador observado divergir do planejado, **não considerar o passe ao destino previsto validado**.

`bonus_abrupt_reset_candidate` identifica reduções abruptas de bônus para zero a partir de 2+, ao invés de atribuí-las ao primeiro decréscimo normal. A heurística ainda não constitui detector definitivo de encerramento do desafio.

## Experimentos

Executar pelo menos uma tentativa isolada com cada direção, de preferência mantendo a mesma configuração inicial do jogo. Comparar destino observado e direção antes de tentar uma sequência de dez passes. Validar visualmente cada resultado: o monitor espacial fornece apenas candidatos.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v072_static.py" -v`. O código ainda requer teste no BizHawk.
