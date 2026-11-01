# PASS LV.1 v0.8.22 — recuperar sequência após receptor inesperado

Ordem preferencial: 6 → 2 → 3 → 4 → 5 → 8 → 9 → 7 → 10 → 11.

Quando um passe chega a um companheiro diferente do planejado, a versão anterior encerrava imediatamente em route_deviation. A v0.8.22 mantém o portador observado (se identificado pelo monitor espacial), registra route_deviation e route_recovered, e escolhe como próximo alvo o primeiro jogador ainda não visitado na ordem preferencial. A seleção não exige que o atual portador seja o previsto na sequência.

Exemplo: se 6 tentar passar a 2, mas o receptor observado for 3, a cadeia continua 3→2; em seguida busca 4, 5, 8, 9, 7, 10, 11, pulando os jogadores já identificados. Os dez participantes continuam sendo contados pelo conjunto espacial de visitas.

Aproximação, checagem de posse, segurança geométrica, alinhamento e modos CALIB:A/B são preservados. A recuperação não comprova posse física da ROM; uma falsa atribuição espacial pode provocar novas tentativas com o portador errado. Não validado no BizHawk.

Auditar csv/pass_auto_v06.csv por route_deviation, route_recovered, receiver_selected, chain_transfer_candidate e chain_complete_candidate. O sucesso depende de confirmação no emulador.
