# PASS LV.1 v0.8.76 — comparação RIGHT vs RIGHT+Y e passe extra 7→10

Base v0.8.75.

## Experimento controlado
Na aproximação 7→10, alternar janelas de oito frames de movimento direcional isolado (A) e movimento direcional + Y (B). A direção continua calculada pelo controlador preditivo; por isso esta é comparação sequencial intrassessão, **não** ensaio causal com estado inicial idêntico. Y só é usado se a bola estiver a até 12 WRAM do jogador 7. Telemetria `approach_710_ab_probe` a cada quatro frames registra fase, posições X/Y de ambos e distância bola–7. As proteções bola–portador da v0.8.74 continuam ativas.

## Passe adicional quando 10 já foi visitado
Se o portador observado for 7, o 10 já tiver recebido e o 11 ainda não tiver recebido, tenta **uma única vez** 7→10 antes de prosseguir a rota normal. A tentativa passa por aproximação e só autoriza o passe dentro dos limites anteriores (distância <=180 WRAM, lateral <=100 e bola nos pés), após pelo menos 24 frames. Eventos: `repeat_710_started`, `repeat_710_pass_authorized`, `repeat_710_result`. Uma segunda recepção do 10 não conta como novo jogador visitado. Não substituir a evidência de todos os jogadores distintos ou de 10/10 oficiais do jogo.

## Atenção
O orçamento absoluto de 210 frames é mantido. Se a aproximação não convergir, o bot para; não força Y ou passe. Os testes são estruturais; testar no BizHawk, comparar o X máximo do jogador 7 e validar o receptor observado.
