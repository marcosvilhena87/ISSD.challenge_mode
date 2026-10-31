# PASS LV.1 v0.5.1 — Início da contagem regressiva do bônus

A v0.5.1 corrige a interpretação da v0.5: transição `0→30` não é ativação comprovada. Agora recebe o nome `bonus_initialized_candidate` no CSV histórico `pass_timers_v05.csv`. A v0.5.1 escreve `csv/pass_bonus_validation_v051.csv` com eventos separados:

- `bonus_increase_or_initialization`: bônus aumenta, inclusive inicialização.
- `first_bonus_decrement`: primeiro decréscimo observado depois do ARM (ex.: 30→29).
- `bonus_decrement`: decréscimos seguintes.

Registra `completion_frame` quando o monitor espacial alcança 10 destinatários candidatos distintos, e `delta_frames` relativo a esse marco. O rótulo `first_decrement_after_spatial_completion_candidate` indica **correlação**, não comprovação de conclusão pelo jogo. Se não houver dez candidatos, rotula `first_decrement_without_spatial_completion`.

## Experimentos recomendados

1. Sessão completa: ARM no início, passes manuais para todos os destinatários e observação visual do bônus.
2. Sessão incompleta: parar antes do décimo receptor e verificar se há decréscimo.
3. Controle negativo: aguardar sem passar e comparar contadores.
4. Repetir as três condições em partidas independentes para avaliar falsos positivos.

O contador de dez decorre da inferência espacial, não de um contador oficial. Este módulo não efetua passes, não escreve RAM e não confirma o chute final. A coleta em `pass_timers_v05.csv`, `pass_spatial_v04.csv` e `pass_bonus_validation_v051.csv` permite comparação entre sessões.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v051_static.py" -v`. Ainda precisa de validação no BizHawk.
