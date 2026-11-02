# PASS LV.1 v0.8.79 — correção vertical e extensões graduais

Base v0.8.78.

- Para 7→10, a cada decisão de movimento a diferença vertical medida (posição real do receptor menos portador) é examinada. Quando o módulo da diferença é >=32 WRAM e o cooldown acaba, executa um curto deslocamento cardinal Up/Down. O cooldown de 12 decisões evita alternâncias verticais a cada instante; em seguida continua perseguindo a coordenada preditiva.
- Atingido o limite atual, uma extensão extra de 30 frames é possível se o portador ganhou >=12 WRAM em X desde o checkpoint anterior **ou** reduziu a distância em >=8 WRAM. Até oito extensões dessa classe; preservadas as extensões tradicionais e critérios de fechamento recente.
- O teto absoluto de 7→10 é 480 frames. Os demais pares preservam o teto de 210. O teto de 480 é um limite de segurança, **não** uma garantia de atingir os 160–180 WRAM. Não executar B sem aprovação dos guardas de posse e distância.
- Evento novo: `approach_710_progressive_extension`. Evento de direção `approach_coordinate_decision` indica `geometry_reason=pair_710_vertical_correction`.
- Preservada a tentativa adicional 7→10 com jogador 10 previamente visitado, sem novo crédito de visita, e o Dash Y permanece desativado por padrão.

## Validação
Carregar main.lua no BizHawk; conferir se X do portador segue progredindo, se |Y10−Y7| cai depois da correção, se a distância atinge <=180 e se todos os limites permanecem. Os testes incluídos são estáticos e não substituem execução dinâmica.
