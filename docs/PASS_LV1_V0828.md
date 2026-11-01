# PASS LV.1 v0.8.28 — controle de aproximação por feedback

Base v0.8.27, que teve 6/10 participantes e não permitiu extensão em 8→9 porque distância e lateral pioraram.

Novo `Ordered.step` avalia as quatro direções cardeais através da geometria projetada e da penalização aprendida por direção. A função custo é o excesso de distância acima de `Feet.MAX_RANGE` mais 2 vezes o excesso de desvio lateral acima de `Feet.MAX_LATERAL`. A direção é recalculada em cada frame, mantendo rajadas fluidas de até quatro frames e pausa neutra. No começo de cada rajada, o bot registra a geometria e a direção. Na pausa, compara o custo geométrico observado; penaliza a direção caso piore ou não melhore, e reduz a penalidade quando produzir melhora. Após 8 rajadas sucessivas sem melhora, interrompe com `approach_no_improvement`. Os limites de 90/210 frames e a extensão progressiva da v0.8.27 continuam.

Novo log `approach_direction_feedback` com resultado, ganho, distância, lateral e número de rajadas ruins. Não altera a política de passes, recuperação adaptativa ou detector passivo de gol da v0.8.26.

**Limitação:** a previsão geométrica de um passo unitário é apenas heurística; os efeitos reais são medidos em frames de emulação. Verificar no BizHawk com o mesmo savestate; nenhuma vitória é presumida.
