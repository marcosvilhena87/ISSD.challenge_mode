# PASS LV.1 v0.8.66 — centro do gol calculado pela geometria do estádio

O desafio não tem goleiro adversário: o slot da antiga referência pode conter `32767,32767`. Deixa de ser usado na rotina de finalização.

Mapeamento WRAM informado pelo operador (endereço, tipo):
- `0x0086` signed 16-bit: `Stadium_ID`, 0–7
- `0x12A2` unsigned 16-bit: `field_length` (X)
- `0x12A4` unsigned 16-bit: `field_width` (Y)
- `0x12F2` unsigned 16-bit: `center_field` (X)
- `0x12D8` unsigned 16-bit: `center_field` (Y)

Hipótese geométrica: centros candidatos nas extremidades do eixo X em `center_x ± field_length/2`, ambos com `y=center_y`. Atualmente, lado direito é hipótese de ataque provisória (`ATTACK_SIDE="right"`); a orientação do gol adversário e a escala devem ser verificadas no BizHawk antes de considerar o mapa calibrado.

Novo `finish_stadium_goal_audit` registra estádio, dimensões, centro e ambos os centros de gol candidatos no `pass_auto_v06.csv`. `Finish.geometry` usa `sample.goal_reference` em vez do slot do goleiro. As proteções impedem chute/aproximação quando a diferença excede 1024 WRAM horizontalmente ou 512 verticalmente, ou se a posição-alvo candidata não estiver à direita da bola. Em casos de incompatibilidade, o bot para com motivo explícito; não adivinha coordenadas nem desfaz o progresso anterior.

Não muda a rota 9→7, 6→7, antecipação 7→10, telemetria dos passes e evidência pós-X. Testes estruturais criados; validar com CSV do BizHawk antes de alegar orientação/escala corretas.
