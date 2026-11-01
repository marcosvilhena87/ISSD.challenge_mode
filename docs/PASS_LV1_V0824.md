# PASS LV.1 v0.8.24 — movimento contínuo

Corrige a sensação de movimento arrastado da v0.8.23, que emitia 1 frame direcional e 1 neutro repetidamente. Agora a aproximação mantém a mesma direção por até 4 frames consecutivos, seguida de 1 frame neutro para amostrar distância e detectar estagnação.

O bot revalida a geometria e a proximidade da bola em todo frame do bloco. Mantém o total máximo de 90 frames direcionais por aproximação e nunca envia B durante esses movimentos. Preserva a detecção de estagnação, troca de eixo, expansão gradual de limites e a adaptação para receptor inesperado.

Verifique no BizHawk se o deslocamento ficou perceptivelmente mais fluido, e examine approach_burst_started, approach_step, approach_progress e approach_axis_switched no pass_auto_v06.csv. Não validado no emulador nesta sessão.
