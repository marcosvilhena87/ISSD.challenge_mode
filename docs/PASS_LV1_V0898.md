# PASS LV.1 — v0.8.98: direções entre todos os pares e recuperação de impasse

Base: v0.8.97.

Os jogadores 2–11 são visitados conforme a fila de primeiros não visitados. Para qualquer dupla de origem e destino, o controlador mede `dx=tx-hx` e `dy=ty-hy` em WRAM, considerando X crescente à direita e Y crescente para baixo. Durante a aproximação pode usar movimentos diagonais; no passe usa direção cardinal dominante **simultânea com B**. A viabilidade de passe ainda depende de distância, geometria, posse e corredor.

Quando a rotina especial está em estado `ready` e o mesmo portador/alvo permanece por 90 frames sem ações especiais, o watchdog registra `queue_watchdog_release`, limpa tentativas expiradas e abre uma janela de 48 frames para o controlador convencional. Uma troca de portador ou destino reinicia a medição. O evento `queue_route_diagnostic` informa diferença de coordenadas, direção e possível motivo de impedimento, incluindo distância excessiva, desalinhamento lateral, bola distante, cooldown ou necessidade de verificar corredor.

Validação dinâmica no BizHawk é obrigatória. A aproximação convencional continua sujeita às restrições existentes; a janela de 48 frames não garante avanço. Recepção detectada espacialmente não confirma a aprovação oficial do desafio.
