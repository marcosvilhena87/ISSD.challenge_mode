# PASS LV.1 v0.8.78 — extensão por fechamento relativo recente

Base: v0.8.77. Objetivo: evitar encerrar a aproximação 7→10 aos ~106 frames apenas por regressão histórica quando a movimentação relativa **recente** demonstra avanço.

## Critério da extensão adicional
- O controlador usa amostras WRAM de velocidade relativa horizontal `closing_vx = v7_x - v10_x`, com histórico limitado a 24 amostras.
- Considera somente os últimos 16 frames.
- Exige pelo menos seis amostras válidas, quatro com fechamento >0,2 WRAM/frame e média de fechamento >=0,35 WRAM/frame.
- Quando as verificações anteriores negam extensão, esse critério autoriza até **duas extensões adicionais** de `Ordered.EXTEND_FRAMES` (30 frames cada), sempre limitadas ao teto absoluto de 210.
- Registra `approach_710_recent_closure_extension`. A regra não ignora a posse, a bola nos pés, o alcance máximo do passe ou a proteção do tempo absoluto.
- Conserva Dash desativado por padrão e a rotina adicional de 7→10 se o receptor 10 já participou.

## Como avaliar
Conferir os registros de `approach_710_relative_closure`, `approach_710_recent_closure_extension`, `approach_extended` e `approach_timeout`. Comparar distância final e mínima com v0.8.77. Se não houver seis amostras positivas suficientes dentro da janela, o encerramento original continuará ocorrendo. Os testes adicionados são estruturais; execução no BizHawk ainda necessária.
