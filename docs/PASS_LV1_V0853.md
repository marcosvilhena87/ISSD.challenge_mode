# PASS LV.1 v0.8.53 — aproximação diagonal UP+RIGHT de 6→7

Base: v0.8.52. Mantida a rota preferencial 6→2→3→4→5→8→9→7→10→11 com tolerância ao receptor observado e garantia lógica de elegibilidade de 7 após o passe 6→2.

Para aproximar o portador 6 do receptor 7, quando as coordenadas reais mostrarem 7 **acima e à direita** (`dx>8`, `dy<-8`), o controlador prioriza **UP+RIGHT sem B**, como movimento, não como execução de passe. A regra usa até quatro avaliações de rajada e é desativada caso distância e desvio lateral cresçam juntos mais de 2 unidades, ou caso após duas avaliações não haja deslocamento detectável do portador. A checagem de bola aos pés permanece antes do comando; feedback de WRAM separa deslocamento do portador e do receptor.

Novo evento `approach_67_diagonal_feedback`: crescimento de distância e lateral, deslocamento do portador, número de avaliações e estado de desativação. Quando a diagonal não é indicada pela geometria ou foi desativada, usa-se o seletor anterior com seus mecanismos de progresso recente e proteção de regressões.

Importante: **UP+RIGHT aqui orienta a movimentação**, não é o passe em si. O passe continua exigindo direcional+B quando a geometria real permitir. Permanecem distância mínima de 24 WRAM, janela neutra de 6→7, limite de segurança de 210 frames e o processo de finalização pós-10/10.

Testes estáticos adicionados. Necessária execução real no BizHawk para verificar a eficácia.
