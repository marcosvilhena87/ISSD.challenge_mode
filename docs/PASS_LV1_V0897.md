# PASS LV.1 v0.8.97 — prioridade à fila de não visitados

Base v0.8.96. A função `first_unvisited` procura o primeiro ID ainda não observado no intervalo 2–11 em ordem crescente, excetuando o portador corrente. O alvo da fila tem prioridade sobre rotas especiais 9→7, 7→10 e devoluções programadas. O evento `queue_target_changed` registra mudanças na fila; `queue_holder_changed` registra mudanças de portador. O evento `relay_coordinates` passa a usar a fila para a escolha de alvo exibido.

O planejador universal e o planejador secundário só escolhem um apoio bloqueador quando há geometria válida e o apoio reduz em mais de 12 WRAM a distância restante ao alvo primário, além de exigir corredor secundário livre. São mantidos limite de duas tentativas e proteção contra retorno imediato. O evento `universal_support_rejected` pode indicar `no_queue_progress`.

Os eventos espaciais `long_710_receiver_observed` e de troca inesperada de portador continuam sendo evidência observacional e não sucesso oficial. Testar dinâmica no BizHawk. Importante: não há prova de que uma distância menor sempre produza um passe correto; a regra é uma restrição geométrica conservadora.
