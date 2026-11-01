# PASS LV.1 v0.8.46 — retorno padrão 9 → 8

Quando o monitor espacial identifica o **jogador 9 como portador**, a escolha padrão passa a ser **repassar para o jogador 8**, mesmo que o 8 já tenha participado da sequência. O retorno 9→8 é feito **uma vez por cadeia automática**; após a transferência candidata 9→8, marca-se `nine_to_eight_done=true` e o controlador retoma a seleção dos jogadores ainda não visitados (por exemplo, 7, 10, 11).

O retorno ao jogador 8, quando ele já foi visitado, não incrementa a contagem de jogadores distintos. A regra de dez jogadores permanece baseada em `spatial.visited` e a distância mínima global de 24 WRAM permanece aplicada. Limite da cadeia de 18 passes e todas as verificações de posse e geometria continuam ativos.

Eventos de auditoria: `route_9_to_8_completed` (somente após transferência candidata 9→8), com `repeat_receiver` para diferenciar um retorno de uma primeira visita. O código do movimento relativo 8→9, a preparação UP→neutro→UP+B 6→3 e os oito RIGHT de 5→8 não foram alterados.

Ainda falta validação no BizHawk. Uma posse observada posteriormente no jogador 9 não demonstra que a cadeia automática chegou a ele: o novo comportamento só ocorre enquanto a cadeia estiver ativa.
