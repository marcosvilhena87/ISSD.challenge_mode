# PASS LV.1 — v0.9.14: alinhamento exclusivo 6→2 e 5→8

Base v0.9.13. Dois controles exclusivos no ponto final de arbitragem, antes de `joypad.set`:
- 6→2 quando o 6 é portador e o 2 ainda não foi visitado;
- 5→8 quando o 5 é portador e o 8 ainda não foi visitado.

Cada prioridade aceita uma única tentativa por inicialização Lua, com máximo 78 frames, deslocamento do portador <=155 WRAM, distância inicial <=320 WRAM, bola até 18 WRAM dos pés e watchdog de progresso de 14 frames. Somente emite B quando a distância até alvo <=175 WRAM, |dy|<=95 WRAM e corredor sem bloqueador geométrico. Quando distancia<=200 e |dy|>95, anda apenas verticalmente para corrigir o problema detectado na v0.9.13. Um único B por controle, saída segura no timeout ou perda de posse. O gate final de direção usa o receptor exclusivo, evitando redirecionamento.

A conclusão 10/10 passa a exigir `completion_frame` observado antes do zero do cronômetro principal; dez participantes detectados fora do prazo geram `chain_complete_out_of_time` sem autorização de término. O instante é comparado ao último estado do relógio disponível, que é lido mais adiante no mesmo loop — assim convém confrontar eventos com o CSV do relógio.

Novos eventos: `exclusive_priority_started`, `exclusive_priority_move`, `exclusive_priority_B`, `exclusive_priority_fallback`. O monitor de score WRAM, passe convencional de fallback e finalização existentes permanecem.

ATENÇÃO: esta branch é experimental; testes estáticos não confirmam sintaxe completa nem recepção efetiva no BizHawk. Comparar Time Score e taxa de conclusão com v0.9.9 (recorde visual 309, Time Score 35).
