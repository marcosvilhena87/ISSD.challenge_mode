# PASS LV.1 v0.9.16 — progresso real antes de movimentar

Base v0.9.15; referência de maior pontuação WRAM: v0.9.14, 370 pontos, Time Score 99.

**6→2:** movimento vertical quando |dy|>95, permitindo diagonal somente quando a componente horizontal é significativamente maior (|dy|<=0,8|dx|, distância >230 e |dx|>90). Preserva limite exclusivo de 66 frames, proteção de posse e de corredor, um único B, e fallback sem progresso.

**5→8:** observa a distância ao receptor frame a frame; se aumentar por 5 frames consecutivos, abandona com `distance_increasing`. Também abandona após 12 frames, caso a distância continue acima de 250 WRAM e o melhor ganho em distância seja inferior a 15 unidades (`poor_progress`). Isso evita consumir a janela de controle exclusivo em uma rota claramente distante. O restante da estratégia assume após o fallback.

Logs de `exclusive_priority_move` agora incluem `worse_frames`, além de `vertical_remaining` e `vertical_best`. Mantidos score WRAM, validação temporal de fronteira, controle final de direção e finalização X.

São heurísticas experimentais; exigem execução real no BizHawk e comparação A/B antes de considerar regressão ou melhora comprovada. Teste estático não é teste de sintaxe Lua.
