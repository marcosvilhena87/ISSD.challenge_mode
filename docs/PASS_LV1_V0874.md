# PASS LV.1 v0.8.74 — Dash com monitoramento bola–portador

Base v0.8.73. Na execução anterior o jogador 7 aproximou-se em 7→10 usando Y mas a geometria da bola terminou em `ball_not_at_feet`.

## Mudanças
- Substitui a rajada contínua RIGHT+Y de 24 frames por rajadas de 8 frames.
- Registra a distância euclidiana bola→jogador 7 (`approach_710_ball_gap`), em WRAM.
- Quando a separação excede 18 WRAM durante Dash ativo: solta imediatamente todos os botões e entra em até três observações neutras (`approach_710_dash_ball_pause`).
- Se a bola retorna a <=18 WRAM, limpa o estado da rajada e volta à decisão controlada (`approach_710_dash_ball_recovered`). Caso contrário encerra sem forçar passe (`approach_710_dash_ball_unrecovered`).
- Mantém guardas de posse de Ordered.step, alvo 160–180 WRAM e teto absoluto de 210 frames.

## Validação
Comparar a distância bola–7, o avanço WRAM do portador por frame e o fechamento para o receptor 10. A recuperação em três frames é hipótese experimental e não prova manutenção de posse. Não é garantido completar o passe ou o desafio. Testes incluídos são estruturais.
