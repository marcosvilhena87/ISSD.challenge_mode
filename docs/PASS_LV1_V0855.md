# PASS LV.1 v0.8.55 — passe principal 9→7, alternativa 6→7

Base: v0.8.54.

**Prioridade da rota:** depois de alcançar 9, a direção principal para um 7 ainda não visitado é 9→7. Se a tentativa for interceptada e a bola chegar ao jogador 6, 6→7 passa a ser uma alternativa válida. Um 6 previamente visitado em 6→2 continua apto a portar novamente a bola. Não marcar 7 como visitado antes de a recepção ser observada.

A função `Ordered.next` prioriza explicitamente 9→7 quando o portador atual é 9 e 7 está não visitado; quando 9 já foi visitado, 7 ainda não e o portador atual é 6, devolve o alvo 7 por `fallback_6_to_7`. Fora desses casos mantém a ordem geral e a adaptação aos receptores efetivos.

**Auditoria do comando físico:** a classificação `Up_Right` passa a identificar rajadas UP+RIGHT tanto em 8→9 quanto em 6→7. O evento `approach_coordinate_decision` inclui `geometry_reason` e os flags UP/RIGHT. `approach_7_joypad_commit` registra os botões reais imediatamente antes de `joypad.set(buttons,1)`, quando há movimentação direcional rumo a 7, além da direção registrada e sinalização de B. Serve para diferenciar decisão, retenção da rajada e aplicação ao controle.

Não é confirmação de movimentação real nem de sucesso de passe. Preserva rota adaptativa, feedback relativo, proteção 8→9, distância mínima 24 WRAM, limite absoluto 210 frames e mecanismo de finalização após 10/10.

Testes estáticos incluídos. Validar no BizHawk a sequência 9→7; só testar 6→7 quando o jogo efetivamente retornar a posse ao jogador 6.
