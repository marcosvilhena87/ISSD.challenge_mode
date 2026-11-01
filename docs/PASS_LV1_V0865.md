# PASS LV.1 v0.8.65 — tentativa experimental antecipada 7→10

Base: v0.8.64. O novo `lua/challenge/pass_early_v0865.lua` autoriza **uma tentativa de passe antecipado 7→10** antes de completar toda a perseguição. O teste é estritamente limitado ao par 7→10, após pelo menos 24 frames de aproximação, com distância inicial até 420 WRAM, lateral até 160 WRAM e bola a no máximo 18 WRAM dos pés do jogador 7. Distâncias maiores não autorizam o disparo.

Ao encontrar geometria elegível, o controlador abandona o movimento RIGHT contínuo e usa a sequência original `Auto.step` de mirar, soltar e pressionar B; evento `early_710_trial` em `csv/pass_auto_v06.csv` registra distância, lateral e confiança `experimental_unverified`. O evento só demonstra que foi autorizada uma tentativa, **não recepção**. Compare `pass_reach_v0864.csv` (distância inicial, distância percorrida, caminhada dos dois jogadores, recepção candidata) com as telemetrias de resultados.

O limite 420 é uma faixa exploratória e não significa que a bola alcance 420 WRAM, tampouco taxa garantida de recepção. Se não houver condições seguras, prossegue a lógica tradicional de aproximação, conservando o teto absoluto de 210 frames. O par 9→7 continua prioritário e o 6→7 usa UP+RIGHT quando necessário. O chute e o monitor de gol permanecem inalterados.

Teste estático: `python -m unittest discover -s tests -p test_pass_v0865_static.py`. Necessária validação real no BizHawk.
