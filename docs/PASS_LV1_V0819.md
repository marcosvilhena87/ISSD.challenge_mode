# v0.8.19 — expansão gradual dos limites durante a mesma execução

Quando o planejador retorna no_reachable_target, a automação tenta até quatro níveis adicionais no mesmo frame, reavaliando a rota após cada aumento. Uma rota encontrada interrompe a expansão.

| Nível | Distância máxima | Desvio diagonal secundário |
| --- | ---: | ---: |
| 0 | 190 | 72 |
| 1 | 215 | 84 |
| 2 | 240 | 96 |
| 3 | 265 | 108 |
| 4 | 290 | 120 |

Cada nova instância de passe inicia no nível zero. O nível persiste entre replanejamentos pré-B da mesma instância. Todos os demais filtros, incluindo bola próxima ao portador e alinhamento ativo da v0.8.18, continuam exigidos antes de B.

Registros: limits_expanded e limits_exhausted em csv/pass_auto_v06.csv. O teto não representa uma distância validada para a física de passes do jogo. Quando nenhum alvo é encontrado mesmo no limite máximo, a cadeia é interrompida sem passe especulativo.

Para testar após iniciar main.lua:

    @("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","AUTO:ON","ARM") |
      Add-Content ".\\txt\\pass_bot_commands_v01.txt"

Comparar número de participantes, passes que terminam sem recepção e eventos de expansão no CSV. Validação prática BizHawk pendente.
