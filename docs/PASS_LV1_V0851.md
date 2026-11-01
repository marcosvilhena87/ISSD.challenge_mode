# PASS LV.1 v0.8.51 — controle horizontal em 7→10

Base: v0.8.50. A alteração é específica para o trecho 7→10.

Quando o receptor 10 está mais de 20 unidades WRAM à direita do jogador 7, priorizar **RIGHT desde o início**, sem depender de duas rajadas produtivas anteriores. O controlador mantém medidas de movimento relativo (avanço do portador, afastamento do receptor) e registra `approach_710_steering_feedback` com contagem de rajadas RIGHT imóveis.

Quando o desalinhamento vertical for elevado (|dy| > max(90, 0,8×|dx|)), permitir correção UP/DOWN somente quando existir amostra de movimento dessa direção. Também pode ocorrer correção vertical limitada após duas rajadas RIGHT sem progresso observado. A prioridade geométrica evita LEFT quando o receptor continua claramente à direita, sem precisar suprimir os mecanismos globais para os demais pares.

Permanecem: posse/bola aos pés, limites de aproximação e teto absoluto de 210 frames, distância mínima global de 24 unidades, rota preferencial 6→2→3→4→5→8→9→7→10→11 com tolerância ao receptor real, passes calibrados anteriores e registros WRAM.

Testes estruturais adicionados; a efetividade depende de nova execução no BizHawk.
