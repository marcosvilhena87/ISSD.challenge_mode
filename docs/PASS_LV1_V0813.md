# PASS LV.1 v0.8.13 — finalização experimental X

A finalização é **opt-in**. Ativar `FINISH:ON` **antes** de `ARM`. Sem esse comando, o comportamento da v0.8.12 permanece inalterado.

## Travas para disparo

1. Identificação espacial de dez jogadores distintos (incluindo o portador inicial).
2. Primeiro decremento de bônus **posterior** à conclusão espacial, observado pelo monitor.
3. Portador espacial estável no frame de preparação.
4. Janela máxima de 240 frames após conclusão espacial e 180 frames após primeiro decremento.
5. Dois frames de preparação sem botões; um único frame com X + direção; sem B junto com X.

## Mira preferencial ao centro

O mapa PASS disponível contém as coordenadas da bola e do goleiro, mas **não uma coordenada aferida do centro da baliza**. A v0.8.13 mira horizontalmente no sentido do goleiro e inclina verticalmente para sua altura quando o desvio ultrapassa 24 unidades. Trata-se de heurística experimental (`goalkeeper_y_proxy`), que **não garante** o centro do gol nem a marcação de gol. Se a direção horizontal for ambígua (distância X < 16), aborta o disparo.

## Execução

```powershell
@("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","FINISH:ON","AUTO:ON","ARM") |
 Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Para testar **sem chute**, omita FINISH:ON.

## Auditoria

Consultar `csv/pass_auto_v06.csv` (`finish_completion_and_bonus_observed`, `finish_shoot_pulse`); `csv/pass_finish_v07.csv`; `csv/pass_inputs_v081.csv` (X e direção); `csv/pass_bonus_validation_v051.csv`; `csv/pass_spatial_v04.csv`. Ausência de `finish_shoot_pulse` indica que alguma condição não foi atendida, não necessariamente erro.

Validação prática no BizHawk ainda necessária. O reconhecimento oficial do gol não está mapeado.
