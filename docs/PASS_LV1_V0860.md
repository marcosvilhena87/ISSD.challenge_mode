# PASS LV.1 v0.8.60 — recuperar 6→7 e validar referência do goleiro

Base: v0.8.59. Sem alterações à rota principal 9→7, à lógica 7→10 ou ao monitor pós-chute semelhante ao DRIBBLE.

## Recuperação 6→7
Uma diagonal UP+RIGHT que aumente a distância/desalinhamento continua sendo desativada conforme a proteção anterior. A rotina de decisão agora pode tentar cardinal UP/DOWN ou RIGHT/LEFT priorizando o maior erro geométrico, com até oito decisões especiais. Após falha do probe, permite **uma única** retomada cardinal no eixo alternativo, apenas se houver pelo menos 16 frames disponíveis antes do limite absoluto de 210. Registra `approach_67_cardinal_retry`, evita repetição ilimitada, não força B.

## Proteção de coordenadas
A posição da bola e do goleiro deve conter números finitos na faixa [-4096,4096]. Diferenças absolutas superiores a 1024 no X ou 512 no Y indicam domínios espaciais incompatíveis nesta heurística: resultado `goalkeeper_coordinate_mismatch`; nenhuma aproximação ou X será enviada nessa condição. Tais limites são **guardas experimentais**, não demonstração de coordenadas calibradas. A posição do goleiro continua proxy — não linha do gol.

Aproximação máxima de 120 frames e distância horizontal de 135 unidades para autorizar o X permanecem as da v0.8.59, assim como a janela posterior de 300 frames e `pass_shot_trajectory_v0859.csv`.

Teste estrutural: `python -m unittest discover -s tests -p test_pass_v0860_static.py`. Validação no BizHawk pendente.
