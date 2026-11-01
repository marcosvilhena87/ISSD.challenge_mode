# PASS LV.1 v0.8.62 — manter botão pressionado durante deslocamento

Base: v0.8.61. Hipótese do experimento: movimentação arrastada causada por rajadas de quatro frames, intercaladas com avaliações e frames neutros.

## Mudança
- **7→10:** quando RIGHT é escolhido sem LEFT nem B, pressiona RIGHT por até **24 frames consecutivos** em vez de rajadas de quatro.
- **6→7:** quando UP+RIGHT é escolhido sem B, pressiona ambos simultaneamente por até **12 frames consecutivos**.
- Outros pares mantêm duração anterior. Continua havendo leitura/revalidação da posse e da geometria em cada frame via `Ordered.step`; não é um botão permanentemente travado. Após cada janela há uma medição neutra para feedback. A duração efetiva respeita também o limite local da aproximação e qualquer orçamento de recuperação.
- Eventos `approach_continuous_hold_started` e `approach_continuous_hold_ended` indicam a janela e o alvo em `pass_auto_v06.csv`.

## Proteções e restrições
A rota 9→7 principal, 6→7 alternativa, teto absoluto de 210 frames, verificação do goleiro, trajetória pós-X e monitor de gol DRIBBLE continuam preservados. A alteração não confirma que o movimento no jogo será mais rápido: é preciso comparar velocidade WRAM por frame e taxa de chegada de 7→10 no BizHawk.

Teste estrutural: `python -m unittest discover -s tests -p test_pass_v0862_static.py`.
