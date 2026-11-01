# PASS LV.1 v0.8.61 — 6→7 com prioridade UP+RIGHT e auditoria de coordenadas

Base: v0.8.60. A prioridade principal continua 9→7; se a bola retornar ao jogador 6, 6→7 é a alternativa, com movimento **UP+RIGHT** como escolha preferencial quando o jogador 7 estiver acima e à direita.

## Correção de regressão
Antes, uma só rajada UP+RIGHT com aumento de distância e desalinhamento desativava a diagonal, mesmo se o receptor 7 se movimentasse ao mesmo tempo. Agora, a desativação requer **três avaliações consecutivas** de regressão simultânea de distância e desalinhamento, ou três avaliações consecutivas sem deslocamento do portador. Avaliações favoráveis zeram a sequência correspondente. Há limite de seis avaliações diagonais antes de o controlador seguir a recuperação existente. A recuperação cardinal permanece como *fallback*, não como substituição da diagonal.

Evento `approach_67_diagonal_feedback` acrescenta `regressions` e `stalls` para diferenciar movimento real, fuga do receptor e imobilidade. Nenhuma regra aumenta o limite absoluto de 210 frames.

## Origem dos dados do goleiro
`lua/challenge/pass_spatial_v04.lua` mapeia a bola em WRAM `0x042A/0x042C` e o goleiro (slot 1) em `0x052A/0x052C`, lidos como inteiros *signed 16-bit*. Isso explica a **origem do dado**, mas não valida que o slot 1 esteja no mesmo sistema espacial que a bola nem que seja uma coordenada confiável para mirar.

O novo evento `finish_goalkeeper_wram_audit` registra os quatro valores, offsets, dx/dy e a indicação explícita `goal_reference=unverified`, antes de iniciar a aproximação final. A proteção v0.8.60 continua bloqueando aproximação/chute se as diferenças forem incompatíveis. A v0.8.61 **não inventa um endereço do gol** nem relaxa as proteções.

A cadeia de 10/10, a trajetória pós-X e a observação de gol derivada do DRIBBLE permanecem. Testes estruturais adicionados, sem execução de emulador.
