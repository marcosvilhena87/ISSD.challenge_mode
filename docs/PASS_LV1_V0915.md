# PASS LV.1 v0.9.15 — alinhamento adaptativo de 6→2

Base: v0.9.14 (pontuação candidata 370 na WRAM, Time Score 99). Preserva **5→8** e a validação temporal corrigida da branch v0.9.14.

A alteração concentra-se na aproximação exclusiva 6→2. Quando |dy|>95 WRAM, prioriza movimento vertical desde o início. Para distâncias >220 WRAM e |dx|>75, usa diagonal para encurtar caminho; depois prioriza Y. Mantém verificação da bola a até 18 WRAM dos pés, proibição de B com corredor bloqueado e B único se distância<=175 e |dy|<=95.

O prazo máximo exclusivo 6→2 cai de 78 para 66 frames. Há fallback antecipado `vertical_stall` após 26 frames se a redução vertical ficar 18 frames sem progresso. A análise geral de progresso continua protegida, considerando separadamente progressos na vertical. As tentativas 5→8 permanecem com 78 frames e lógica de movimento original.

Instrumentação: `exclusive_priority_move` acrescenta `vertical_remaining` e `vertical_best`. Os eventos de início, B e fallback continuam. O objetivo é poupar frames no início; **não há garantia de que a tentativa 6→2 funcione** ou aumente o Time Score. Comparar com a referência oficial v0.9.9 (309) e a melhor execução WRAM v0.9.14 (370).

Testes em `tests/test_pass_v0915_static.py` são estruturais; a validação dinâmica com BizHawk é necessária.
