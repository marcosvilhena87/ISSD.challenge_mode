# PASS LV.1 v0.8.17 — alinhamento geométrico A–bola–B

O jogador A é o portador espacial inferido; B é o receptor pretendido. O objetivo é evitar passes para espaços vazios quando a bola não se encontra no eixo que conecta A a B.

Critérios iniciais:
- Distância bola–A <= 18 unidades.
- Desvio perpendicular da bola em relação à linha A–B <= 12 unidades.
- Projeção longitudinal da bola na direção de B >= -5 unidades (pequena tolerância atrás de A).
- Requisitos existentes de distância, diagonal e movimento do receptor continuam aplicáveis.

Matematicamente, usando v = B - A e w = bola - A, o desvio lateral é abs(w.x*v.y - w.y*v.x)/|v|. A bola não precisa estar no meio dos jogadores: em posse normal estará próxima de A.

A checagem ocorre na escolha do receptor e imediatamente antes do primeiro B. Em caso de reprovação pré-B, a rotina da v0.8.16 tenta replanejar com até três tentativas, usando eventos retarget_requested_*. Se não houver receptor alinhado, interrompe sem lançar a bola.

Importante: geometria aproximada não comprova direção física do chute, orientação real do sprite nem ausência de adversários na trajetória. Validação no BizHawk pendente.
