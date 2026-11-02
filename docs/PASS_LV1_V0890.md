# PASS LV.1 — v0.8.90: coordenadas e direção para todos os jogadores

Base: v0.8.89.

## Regra de coordenadas WRAM
X cresce para a direita; Y cresce para baixo. A função `pair_geometry(sample,from,to)` mede X/Y de qualquer portador e receptor, calcula `dx=tx-hx`, `dy=ty-hy`, a distância euclidiana e a direção cardinal no eixo dominante. Quando o Control Pad + B for executado, o comando usa a direção recalculada com as coordenadas correntes da dupla.

## Reposicionamento
Em corredores bloqueados, `lane_escape` simula quatro pequenos deslocamentos possíveis do portador (Up/Down/Left/Right de 12 WRAM) e prefere a alternativa que desobstrua a linha e limite o aumento da distância. A escolha é uma projeção geométrica, não um movimento real garantido. O controlador executa o deslocamento curto habitual (6 frames), reavalia coordenadas e corredor e não força B se o bloqueador persistir.

## Registros
O evento `relay_coordinates` é emitido a cada seis frames para o par selecionado: `hx,hy,tx,ty,dx,dy,distance,direction` e botões Up,Down,Left,Right,B realmente montados na saída do controlador. O evento `long_710_directional_b` também registra geometria no instante da decisão.

A rotina mantém o passe direto 9→7, avanço controlado 7→10, recuperação de único jogador ausente e devolução 10→7→10; as condições de segurança e o limite de tentativas são preservados. A confirmação da recepção ainda é espacial, não prova oficial de conclusão. Exige validação dinâmica no BizHawk.
