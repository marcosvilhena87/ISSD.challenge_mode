# PASS LV.1 — v0.8.99: alinhamento diagonal com medição WRAM

Base v0.8.98. Durante a fila de jogadores não visitados, se o portador atual tem a bola (distância <=18 WRAM) e o desvio vertical ao próximo alvo excede 100 WRAM, inicia-se a fase `align` antes do passe.

A movimentação principal utiliza ambos os eixos conforme o sinal de `dx=tx-hx` e `dy=ty-hy` (X cresce para a direita; Y para baixo), até 18 frames ou 42 WRAM medidos. Termina também quando o desvio vertical cai para <=100. Registra `queue_alignment_started` com coordenadas relativas e `queue_alignment_result` com caminhada real, ganho de distância, desvio restante e razão do encerramento.

Sem progresso mensurável (ganho ou caminhada de pelo menos 5 WRAM), alterna para tentativa vertical pura e horizontal pura. Após três tentativas improdutivas, gera `queue_alignment_fallback` e abre por 48 frames o controle convencional, em vez de repetir a mesma trajetória indefinidamente.

O alinhamento é distinto do lançamento: **B não é pressionado na fase `align`**. O passe continua sendo enviado com direção cardinal dominante e B simultaneamente, após validação de posse, geometria e corredor. A fila de não visitados, passes de apoio e mecanismos anteriores permanecem.

A conclusão dinâmica e efetividade do deslocamento requerem teste no BizHawk. `spatial.visited` e `spatial.holder` são evidências espaciais, não confirmação oficial de êxito no desafio.
