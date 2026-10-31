# PASS LV.1 v0.8 — receptor próximo e alinhamento

A v0.8 muda a seleção de alvo na automação experimental do PASS: entre jogadores de linha 2–11 ainda não visitados, excluindo portador e goleiro, prioriza menor distância euclidiana e penaliza desalinhamento.

`cost = distance + 0.25 * max(0, min(abs(dx),abs(dy)) - 12)`

Valores **experimentais**: tolerância 12 unidades; peso 0,25; até dois frames direcionais de alinhamento antes de manter direção+B por três frames. A correção é *movimentação curta*, não controle validado da orientação do jogador. A ordem dos jogadores poderá divergir do planejado, pois as regras internas de seleção do receptor são desconhecidas.

A estratégia mantém **um passe por ARM**. O receptor é calculado a partir de posições espaciais e pode ser diferente daquele reconhecido em `pass_direction_v072.csv`. Eventos `receiver_selected` e `alignment_correction` são registrados em `csv/pass_auto_v06.csv`, incluindo distância, custo e alinhamento inicial. `pass_direction_v072.csv` registra destino planejado, observado, deslocamento e latência; `pass_spatial_v04.csv` continua indicando mudanças de posse candidatas.

## Execução

No BizHawk, com `main.lua` em PASS LV.1, acrescente ao `txt/pass_bot_commands_v01.txt`:
```text
PASSBTN:B
DIRECTION:AUTO
AUTO:ON
ARM
```

Para repetir outra tentativa, repita `AUTO:ON` e `ARM` em uma nova situação inicial. `STOP` interrompe. `FINISH:ON` **não habilita** a finalização nesta branch; chute automático segue bloqueado.

## Limitações e próximo experimento

Os sinais de posse são inferências pela proximidade da bola; não comprovam recepção oficial. Não se confirma que duas frames de correção melhorem a mira, nem que 12 seja tolerância adequada. Para avaliar, comparar partidas com e sem necessidade de pré-alinhamento, registrando destino pretendido, observado, latência e movimento da bola. Não há automação de dez passes consecutivos nesta etapa. Sem escrita de RAM.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v08_static.py" -v`.
