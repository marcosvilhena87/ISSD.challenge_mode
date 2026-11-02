# PASS LV.1 — v0.9.17 (priorização por gargalos)

Partindo da v0.9.16 (melhor total candidato WRAM 396; Time Score 122), a mudança é pequena e direcionada aos pares lentos observados.

1. **6→2:** após 10 frames sem progresso de distância *nem* alinhamento vertical, retorna à lógica convencional com `initial_motion_stall`, em vez de ocupar 14 frames. Preserva os controles de posse, corredor e limite.
2. **10→11:** passe direto **somente** se o jogador 10 estiver em posse confirmada (bola a até 18 WRAM), o jogador 11 ainda não tiver sido visitado, distância 28–175 WRAM, |dy|<=95 e corredor livre. Não substitui chute X nem sobrescreve um passe B já programado. Log `pair917_direct_10_11`. Se não houver geometria favorável, mantém controlador convencional.
3. **5→8:** reduz de 12 para 9 frames a janela de verificação de progresso insuficiente quando a distância ainda excede 250 WRAM, antecipando fallback; a prioridade exclusiva permanece.
4. **Todos os pares:** `pair917_holder_summary` registra duração em frames de cada período de posse observada, frames com/sem mudança de posição e frame do último B observado. É telemetria aproximada e *não* separa explicitamente início/voo da bola nem prova causa das esperas.

Nenhuma alteração intencional no comportamento 7→10, 4→5, 9→7 ou nos pares rápidos; esses casos são instrumentados antes de qualquer otimização adicional. Mantém finalização X, monitor WRAM e fronteira temporal de v0.9.14.

Validação: testes estruturais incluídos; sintaxe Lua e funcionamento real no BizHawk ainda precisam de execução. Comparar a nova rodada contra a v0.9.16 (396 WRAM).
