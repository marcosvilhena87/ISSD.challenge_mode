# PASS LV.1 v0.8.25 — dois critérios geométricos na aproximação

Base: v0.8.24. Preferência de rota: 6→2→3→4→5→8→9→7→10→11, com recuperação adaptativa para receptores inesperados.

A geometria de `Feet.measure` usa dois critérios simultâneos: distância euclidiana entre portador e alvo (limite inicial 190) e desvio lateral, definido por `min(abs(dx),abs(dy))` (limite inicial 72). Se o lateral ultrapassa o limite, corrige o eixo de MENOR módulo movendo o portador na direção do alvo para reduzir esse componente. Caso contrário, quando só a distância excede o limite, prioriza o eixo maior. Os critérios são reavaliados a cada frame, inclusive durante blocos fluidos de até 4 frames direcionais consecutivos.

Na pausa neutra após cada bloco, registra distancia atual/melhor e lateral atual/melhor. O algoritmo de estagnação considera melhora em qualquer dos dois critérios. Após cada 20 frames direcionais de aproximação, se ainda não alcançou geometria válida, pode elevar um nível de distância e lateral (máximo nível 4). A expansão adicional por duas trocas de eixo continua disponível. Não dispara B durante aproximação e preserva checagens de posse e alinhamento antes do passe.

O limite permanece 90 frames direcionais. A telemetria `approach_progress` inclui `lateral` e `best_lateral`. Os eventos `limits_expanded` incluem `cause=approach_duration` quando aplicável.

A implementação ainda requer teste real no BizHawk; proximidade e recepção espacial não equivalem à validação interna da ROM.
