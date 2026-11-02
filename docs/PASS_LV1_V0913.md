# PASS LV.1 v0.9.13 — arbitragem exclusiva 6→2

Base v0.9.12. Introduz uma arbitragem **no ponto final de saída do controle** (depois dos controladores convencionais e especiais, antes da direção definitiva e de `joypad.set`). Quando o relógio iniciou, a cadeia está ativa, o jogador 6 detém a posse espacial estável e o jogador 2 ainda não foi contabilizado, assume temporariamente os botões.

A tentativa permite no máximo 54 frames (~0,9 s, se 60 fps), distância inicial até 320 WRAM e exige bola até 18 WRAM do portador; caminha diagonalmente conforme o sinal WRAM de X e Y. Só envia um pulso B quando distância <=175, |dy| <=95 e não há bloqueador geométrico. Ao disparar, marca `done` e devolve controle às rotinas existentes no frame seguinte. Em qualquer falha de geometria, posse, distância ou tempo, desiste sem emitir B e retorna ao controle anterior. `finish_X` nunca é substituído.

O gate final de direção usa explicitamente receptor 2 quando o pulso exclusivo está ativo, impedindo que o alvo `autopass.target` reescreva o comando.

Eventos: `exclusive_6_to_2_started`, `exclusive_6_to_2_move`, `exclusive_6_to_2_B`, `exclusive_6_to_2_fallback`.

O monitor de pontuação e a finalização são preservados. Esta é uma tentativa experimental única por inicialização Lua; a repetibilidade e o resultado efetivo 6→2 precisam de validação no BizHawk. Testes adicionados são estruturais.
