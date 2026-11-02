# PASS LV.1 v0.8.86 — prioridade exclusiva e devolução 10→7→10

Base: v0.8.85.

Quando somente um jogador entre IDs 2–11 estiver ausente, o controlador principal deixa de emitir a aproximação usual. A tentativa de passe direcional ao ausente passa a ter prioridade, sempre condicionada à geometria e posse. Corredor bloqueado pode disparar até quatro deslocamentos laterais de seis frames, alternando Up/Down, reavaliando o corredor após cada um. Não há garantia de uma linha aberta nem de recepção.

**Regra 10→7→10:** se o portador observado mudar diretamente de 10 para 7, enfileirar uma tentativa de retorno 7→10, antes da prioridade do ausente. É uma devolução especial, no máximo uma vez por sessão; respeita distância, linha desobstruída, bola próxima e Control Pad+B simultâneos. Transições com detecção intermediária nula podem não ser reconhecidas, pois o gatilho exige mudança observada entre dois portadores válidos.

Logs `csv/pass_auto_v06.csv`: `return_710_queued`, `last_missing_sidestep_started`, `last_missing_sidestep_finished`, `last_missing_sidestep_aborted`, `long_710_started` (`kind=return_7_to_10` ou `kind=last_missing`), `long_710_directional_b`, `long_710_receiver_observed` e `long_710_observation_timeout`.

Limites existentes preservados: 35–410 WRAM, lateral <=100, bola–portador <=18. Corredor: 24 WRAM de tolerância. Esta versão visa priorizar a tentativa segura, sem prometer êxito físico no jogo. Validação dinâmica em BizHawk pendente.
