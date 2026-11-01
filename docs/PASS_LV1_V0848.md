# PASS LV.1 v0.8.48 — Rota padrão e feedback combinado

## Ordem canônica
A sequência padrão agora é **6 → 2 → 3 → 4 → 5 → 8 → 9 → 7 → 10 → 11**, equivalente a `ROUTE={6,2,3,4,5,8,9,7,10,11}`. O algoritmo escolhe o próximo jogador da lista ainda não visitado diferente do portador atual. Quando a transferência observada vai para outro receptor, a cadeia existente atualiza o portador real, registra a transferência candidata e continua buscando os ainda não visitados, sem exigir a rota exata.

## Aproximação por progresso recente
Em cada avaliação de rajada, calcular ganho de distância e de desvio lateral. Ganhos combinados positivos, sem regressões excessivas em nenhum eixo, acumulam uma sequência por direção. Depois de duas boas avaliações consecutivas, preservar a mesma direção por até três novas decisões, reduzindo oscilações de eixo ocasionadas por penalizações antigas. Uma regressão combinada relevante elimina a preferência. Os atalhos específicos 5→8, 8→9 e 6→7 mantêm precedência.

## Segurança
Sem mudança no limite absoluto de aproximação, na distância mínima global 24 WRAM, no controle de posse ou nas exigências de Control Pad+B. Testes estáticos incluídos; comportamento do jogo precisa ser verificado no BizHawk.
