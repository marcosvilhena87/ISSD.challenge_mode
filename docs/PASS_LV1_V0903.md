# PASS LV.1 v0.9.3 — reconciliação de posse

Base: v0.9.2. Preserva a recuperação de approach timeout, os passes corrigidos pela geometria em v0.9.1 e a finalização adaptativa da v0.9.0.

Problema identificado em sessão anterior: a posse espacial mudou para 7 durante tentativa convencional antiga 6→7, que depois terminou com `possession_gate_timeout`; a fila não prosseguiu para 8.

A rotina compara o portador espacial com `autopass.origin` enquanto o controlador está em fase ativa. Se forem diferentes e o portador for um dos dez jogadores de linha, reinicia `Auto.new()`, preserva AUTO, limpa contadores e estado de aproximação, concede 4 frames de transição e registra `possession_spatial_resync` com origem antiga, novo portador, alvo antigo e próximo jogador inédito.

Se `possession_gate_timeout` for retornado com um portador espacial válido e cadeia ativa, reinicializa o controlador e preserva `pass_chain.active`, permitindo nova seleção após seis frames. Registra `possession_gate_restarted` e o portador espacial no diagnóstico do timeout.

Todas as recepções continuam sendo **evidência espacial, não confirmação oficial**. Ainda é preciso validar dinamicamente se o bot ultrapassa 7/10 e completa a finalização.
