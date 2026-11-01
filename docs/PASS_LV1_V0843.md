# PASS LV.1 v0.8.43 — aproximação 8→9 por geometria e feedback WRAM

Base: v0.8.42. A alteração é específica do controlador de aproximação 8→9.

## Estratégia
- Coordenadas da tela: origem no canto superior esquerdo; X aumenta à direita, Y aumenta para baixo.
- A tentativa UP+RIGHT inicial só ocorre quando o jogador 9 está efetivamente acima e à direita do jogador 8 (dx > 10, dy < -10), sob o limite já existente de três tentativas diagonais.
- Após a diagonal ser desativada, selecionar **UP ou RIGHT** pela previsão do custo geométrico. São consideradas as médias de deslocamento efetivamente medidas na WRAM (`state.motion`), quando disponíveis. LEFT e DOWN somente entram como opções quando o receptor passa a estar, respectivamente, à esquerda ou abaixo do portador.
- Registrar `approach_89_feedback` com direção, variação de distância, variação lateral e contador de regressões. Uma direção que aumentou a distância recebe penalização adicional na próxima escolha; melhora reinicia a sequência de regressões.
- Interromper com `approach_89_regression_stop` após duas rajadas de aumento da distância >1,5 ou crescimento acumulado >24. Desabilitar o mecanismo exploratório genérico de recuperação para 8→9, que anteriormente podia disparar direções contrárias ao objetivo.

## Invariantes preservados
- 6→3: dois UP isolados, neutro e UP+B.
- 6→2: UP+B.
- 4→5: pré-Down, neutro e Down+B.
- 5→8: RIGHT em até oito frames, tolerância da v0.8.40 e follow-up neutro.
- Monitor pós-10/10 e pós-X, orçamento absoluto de 210 frames e validação de posse a cada frame.

A versão requer validação real no BizHawk; eventos de transferência permanecem evidências espaciais candidatas.
