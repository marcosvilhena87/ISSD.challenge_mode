# PASS LV.1 v0.8.47 — preservar progresso recente em 6→7

Base v0.8.46. Escopo da mudança: **somente aproximação 6→7**.

- Após uma rajada de direção UP, calcular o ganho positivo de distância e de desvio lateral usando coordenadas WRAM. Duas avaliações sucessivas favoráveis habilitam a preferência por UP, evitando alternar de novo para LEFT, RIGHT ou DOWN enquanto esse progresso recente permanecer válido.
- Se UP deixar de melhorar a geometria em uma avaliação, zerar a sequência favorável; assim, a orientação especial não persiste sem evidência.
- No timeout normal, permitir até **duas extensões de 30 frames** quando houver duas amostras recentes positivas de UP e geometria sem piora significativa. Preservar o teto absoluto `MAX_APPROACH_ABSOLUTE=210`, as verificações de bola aos pés, posse e limites de segurança.
- Registros: `approach_67_up_feedback` para direção, ganho de distância/lateral e sequência; `approach_extended` com `reason=pair_67_recent_up_progress` quando a extensão for acionada.

Permanecem a lógica UP → neutro → UP+B de 6→3, Down+B de 4→5, RIGHT prolongado 5→8, predição curta 8→9, distância mínima global de 24 unidades, e o autoteste de integração corrigido na v0.8.45.

Testes estáticos incluídos; requer execução de fato no BizHawk para confirmar o efeito.
