# PASS LV.1 v0.8.15 — priorizar passes no pé

Motivação: o último passe observado seguiu para uma região sem companheiros. A estratégia passa a restringir o alvo a jogadores acessíveis geometricamente e a verificar o posicionamento do receptor **imediatamente antes do B**.

## Critérios experimentais

- Distância máxima direta entre portador e receptor: **190 unidades de WRAM**.
- Desvio diagonal secundário máximo: **72 unidades** (limita passes de ângulo difícil).
- Deslocamento do vetor portador→receptor desde a escolha: máximo **32 unidades por eixo** antes do primeiro frame com B.
- Passes de apoio para jogadores já visitados continuam possíveis, mas precisam respeitar as mesmas travas nas duas pernas planejadas.
- Mantém prioridade dos participantes inéditos e jogadores 11 e 10 ao final.
- Se nenhum destinatário estiver elegível, interrompe a cadeia e registra `feet_route_blocked`; não lança a bola ao acaso.
- Se o receptor mudar muito de posição durante os quatro frames de orientação, interrompe com `feet_pass_rejected_target_moved`, sem enviar B.

## Limitação

Não há vetor validado de velocidade da bola, orientação real do sprite, força/precisão do passe nem detecção de adversários. Logo, **'passe no pé' é uma preferência geométrica, não uma garantia de recepção**. Os limites de distância e diagonal são hipóteses que precisam de calibração com CSVs e savestates.

## Execução

Reinicie `main.lua` no PASS LV.1 e, opcionalmente com finalização X habilitada:

```powershell
@("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","FINISH:ON","AUTO:ON","ARM") |
 Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

## Auditoria

Verifique `csv/pass_auto_v06.csv` para `feet_route_blocked` e `feet_pass_rejected`, `csv/pass_inputs_v081.csv` para verificar ausência de B no passe rejeitado, e `csv/pass_spatial_v04.csv` para conferir quem efetivamente recebeu. Compare a taxa de `ball_moved_without_transfer` com a v0.8.14 usando o mesmo savestate. 
