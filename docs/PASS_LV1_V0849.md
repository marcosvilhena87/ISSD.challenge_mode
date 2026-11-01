# PASS LV.1 v0.8.49 — movimento relativo e proteção contra regressão em 6→7

Base: v0.8.48. Alterações restritas à aproximação do portador 6 para o receptor 7.

A partir da captura WRAM das posições de ambos os jogadores, o módulo `Ordered.observe_motion` já disponibiliza avanço projetado do portador (`holder_toward`), afastamento projetado do receptor (`receiver_away`) e aproximação relativa (`relative_closing`). A v0.8.49 passa a registrar esses componentes nas fronteiras neutras do trecho 6→7 em `approach_67_relative_feedback`, juntamente com a variação observada de distância e desvio lateral.

Se **duas avaliações consecutivas da mesma direção** aumentarem simultaneamente a distância e o desvio lateral em mais de 1,5 unidade cada, registrar `approach_67_direction_guard` e impedir essa direção nas próximas **três decisões** de aproximação. A restrição expira; uma melhora intermediária limpa a contagem de regressão. A preferência UP baseada em progresso da v0.8.47 não se sobrepõe a um bloqueio temporário de UP.

A medição do receptor não é inferência de intenção. Não confundir regresso causado pelo receptor com ausência de movimento do portador. Os limites de segurança (posse/bola aos pés, 210 frames, geometria real) permanecem ativos.

Preservados: rota preferencial 6→2→3→4→5→8→9→7→10→11 com tolerância ao receptor observado, mínimo global 24 WRAM, 5→8 RIGHT, 8→9 previsão curta, 6→3 UP+B e 4→5 Down+B.

Adicionados testes estruturais; validação do comportamento depende de nova execução no BizHawk.
