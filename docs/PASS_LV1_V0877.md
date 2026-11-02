# PASS LV.1 v0.8.77 — aproximação 7→10 sem Dash e telemetria de fechamento relativo

Base: v0.8.76.

## Mudanças
- Desabilita o Dash Y por padrão na aproximação 7→10; mantém a direção cardinal escolhida pelo controlador e a verificação de bola nos pés.
- Substitui o rótulo ambíguo do experimento A/B por `DIRECTION_ONLY_V0877`; registra os controles efetivamente selecionados em `approach_710_actual_input`, incluindo `actual_Y`.
- Mede a cada amostra a velocidade X real do jogador 7 e do jogador 10, a velocidade relativa `closing_vx=holder_vx-receiver_vx`, a posição X de ambos e a distância bola–portador. Registra `approach_710_relative_closure` a cada 4 frames.
- Quando o deslocamento horizontal do receptor é <=0,4 WRAM/frame durante pelo menos oito frames, registra `approach_710_receiver_slow_window`. Este evento é diagnóstico, não altera o orçamento de movimento nem força passes.
- Mantém a rotina adicional experimental 7→10 quando 10 já foi visitado e 11 ainda não, sem inflar a contagem de visitas.
- Preserva distância de passe, proteção da bola e limite de aproximação 210 frames.

## Validação
No BizHawk, verificar avanço X do portador, taxa de fechamento relativa, se `actual_Y=false` e se há janelas de desaceleração que efetivamente diminuam a separação entre os jogadores. Os testes adicionados são estáticos; não garantem êxito no jogo.
