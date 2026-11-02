# v0.8.72 — perseguição preditiva 7→10

Base v0.8.71. A sessão anterior mostrou portador avançando 31,99 WRAM enquanto receptor escapava 37,91 WRAM, com fechamento negativo.

## Estratégia
- Medir velocidade do receptor 10 usando coordenadas WRAM em amostras separadas por 1–12 frames.
- Descartar leituras anômalas (>12 WRAM/frame por eixo), limitar previsão a quatro frames e 24 unidades por eixo.
- Reorientar o jogador 7 pelo maior erro X/Y da posição prevista do receptor. Quando não há estimativa válida, seguir geometria atual.
- Registrar `approach_710_receiver_velocity` para auditoria e preservar `early_710_close_gate`.
- Não forçar B fora dos limites da v0.8.70: alvo 160, máximo 180 WRAM e lateral 100.
- Segurança: teto absoluto de 210 frames permanece. Se não houver convergência, parar; **não é garantido alcançar 160–180**. Não prolongar indefinidamente uma perseguição em que o receptor corre mais rápido.

## Validação dinâmica
Verificar distância inicial, melhor e final, direção da velocidade prevista, vetor do portador e transferência realmente observada. Os testes estruturais não substituem o experimento no BizHawk.
