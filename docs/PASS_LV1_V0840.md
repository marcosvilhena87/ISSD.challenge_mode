# PASS LV.1 v0.8.40 — oito frames RIGHT reais e progresso lateral

Base v0.8.39. Corrige o terceiro argumento de `math.min`, que mantinha o máximo de quatro frames mesmo quando o primeiro argumento pedia oito. Na aproximação **5→8**, a rajada RIGHT agora pode manter até **oito frames consecutivos**, limitada pelo orçamento restante da aproximação, pela recuperação exploratória (quando ativa), posse e geometria válidas a cada frame.

Ao fim da rajada RIGHT, são acrescentadas **três amostras neutras** de coordenadas do portador e do receptor (`approach_right_followup`), seguidas da amostra de feedback habitual. Isso permite observar resposta atrasada sem confundir os frames neutros com a medição de um novo comando.

No feedback `guard_right`, variação horizontal pequena ou nula não interrompe automaticamente se a distância diminuir ou houver redução do erro lateral (`right_lateral_progress`). A imobilidade horizontal persistente tem limite próprio: três avaliações sem melhora significativa podem bloquear RIGHT com `persistent_horizontal_still`. Regressões fortes e acumuladas continuam bloqueadas.

Permanecem o pré-Down+Down+B em 4→5, a rota 6→3→2, a diagonal 8→9 quando o alvo está acima à direita, as verificações de posse/bola por frame e o teto global de 210 frames.

Teste de estrutura adicionado; validação em BizHawk permanece obrigatória.
