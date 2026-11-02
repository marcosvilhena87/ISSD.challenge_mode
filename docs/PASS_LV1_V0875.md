# PASS LV.1 v0.8.75 — ultrapassar estagnação do jogador 7

Base v0.8.74. A experiência anterior mostrou RIGHT+Y quase sem movimento horizontal, enquanto a separação bola-portador ultrapassou 18 WRAM.

## Modificação
- Observar a posição WRAM do jogador 7 a cada frame durante a aproximação 7→10.
- Após seis leituras consecutivas sem alteração significativa de X nem Y (<0,5 WRAM), desabilitar Dash Y na aproximação atual.
- Liberar a rajada retida e recalcular a direção cardinal sem Y. Registrar `approach_710_dash_stall_fallback` e `approach_710_direction_only`.
- O controle continua tentando avançar dentro do orçamento de até 210 frames, sem ignorar validações da bola, posse, distância-limite e limites de passe.
- Se RIGHT puro também não ultrapassar a mesma coordenada, investigar colisões, limites espaciais, orientação e mapeamento dos comandos; insistir indefinidamente pode ser ineficaz.

## Validação
Comparar holder_x/holder_y após o fallback e a distância 7→10. Confirmar que Y fica desligado na fase alternativa, que B não é enviado fora de 180 WRAM e que o limite 210 não é excedido. Os testes estruturais não demonstram ultrapassagem real no BizHawk.
