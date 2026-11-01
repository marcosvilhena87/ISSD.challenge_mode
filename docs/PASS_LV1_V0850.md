# PASS LV.1 v0.8.50 — movimento relativo na aproximação 7→10

Base: v0.8.49; alterações concentradas em 7→10.

A cada fronteira neutra após uma rajada, registrar a projeção do deslocamento WRAM do jogador 7 na direção do jogador 10 (`holder_toward`), quanto o jogador 10 se afasta (`receiver_away`) e a aproximação resultante (`relative_closing`). O evento `approach_710_relative_feedback` inclui também ganho real de distância e sequência de RIGHT.

Quando duas rajadas RIGHT consecutivas demonstrarem avanço projetado do portador >0,5 unidade, e o receptor continuar geometricamente à direita, manter RIGHT na decisão seguinte. Se uma rajada RIGHT não apresentar avanço, zerar a sequência. O afastamento do receptor não invalida, por si só, um RIGHT que movimentou o portador em direção ao alvo.

Na fronteira de timeout, `Ordered.can_extend` considera uma exceção restrita a 7→10 para duas extensões de **30 frames**, quando houver sequência recente de RIGHT e avanço observado do portador, mesmo que a distância total esteja afetada pela fuga do receptor. O teto absoluto global de **210 frames** continua em vigor. Eventos `approach_extended` indicam `reason=pair_710_recent_right_progress`.

Preservados: ordem preferencial 6→2→3→4→5→8→9→7→10→11, tolerância ao receptor observado, distância mínima global de 24 unidades, 5→8 RIGHT, previsão 8→9, guarda relativa 6→7 e autoteste de integração. Testes estáticos incluídos; execução no BizHawk necessária.
