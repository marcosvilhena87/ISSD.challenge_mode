# PASS LV.1 — v0.9.9: planejamento pass-first com compromisso

Base v0.9.8; v0.9.7 permanece a referência de sucesso oficial (291 pontos; Time Score 17). O objetivo é reduzir caminhadas na fase de passes, sem trocar um percurso seguro por um atalho local ruim.

A versão avalia cada passe direto inédito que respeite a geometria já exigida (distância 28–185 WRAM, desvio vertical até 105 WRAM, corredor sem bloqueio). Além do custo imediato `distância+0,30*abs(dy)`, estima o menor custo até mais um jogador inédito. A segunda perna paga penalidade equivalente de 220 unidades quando a distância excede 185 WRAM, representando a necessidade provável de caminhada; sua contribuição ao escore é 65%. A seleção abandona a ordem padrão apenas quando a vantagem estimada excede 25 unidades. Trata-se de heurística de deslocamento, não de segundos cronometrados.

O destino da fila fica comprometido enquanto o portador permanecer e houver tentativa ativa no controlador convencional ou na rotina especial, evitando oscilações a cada nova amostra. Com troca de portador ou visita do destino, a escolha pode ser revista. Watchdog e alinhamento consultam o mesmo compromisso. Os eventos `time_score_pass_first`, `queue_target_changed` e `time_score_new_visitor` continuam disponíveis.

**Limitação:** a proteção de alvo atua na fila especial, não modifica diretamente todas as escolhas internas do controlador convencional. Os timeouts legados ainda podem consumir tempo; esta versão não promete abandono global antecipado. A/B recomendado com v0.9.7 em dez tentativas independentes por versão, comparando taxa de conclusão, Time Score e tempo até cada novo visitante.

Nenhuma alteração em `pass_finish_v07.lua`; recarga explícita e finalização de v0.9.7 preservadas.
