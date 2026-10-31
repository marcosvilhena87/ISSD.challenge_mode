# PASS LV.1 v0.6 — passes automáticos experimentais (opt-in)

**ATENÇÃO: botão e efeito da direção NÃO foram validados no PASS LV.1.** O projeto só conhece coordenadas da bola e jogadores e inferências espaciais; a implementação é uma primeira experiência com controles do SNES e pode falhar. Nenhuma escrita RAM. O botão do passe deve ser escolhido pelo operador após teste manual.

## Como testar

1. Faça `git fetch` e use `feature/pass-lv1-autopass-v06-experimental`; mantenha a ROM e o BizHawk corretos.
2. Escreva `PASS` em `challenge_mode.txt` e inicie `main.lua`.
3. Selecione manualmente PASS LV.1 e posicione o jogo no início.
4. No arquivo `txt/pass_bot_commands_v01.txt`, acrescente **uma linha por comando**:
   - `PASSBTN:B` — exemplo apenas, **não é confirmação de que B passa a bola**. Valores permitidos: A, B, X, Y, L, R.
   - `AUTO:ON` — habilita automação somente para o **próximo** ARM.
   - `ARM` — inicia tentativa automatizada se o monitor reconhecer o candidato PASS LV.1.
5. `AUTO:OFF` desliga a automação imediatamente; `STOP` desarma e solta todos os botões.
6. Leia `csv/pass_auto_v06.csv`, `pass_spatial_v04.csv`, `pass_bonus_validation_v051.csv`.

A política é simples: identifica posse candidata estável pela proximidade da bola, calcula rota Held–Karp por **distância euclidiana** aos receptores não visitados, emite um frame de direção, um frame neutro e um pulso de um frame no botão escolhido. Espera até 100 frames por mudança de posse e limita a 15 tentativas/3600 frames. Encerra ao atingir 10 receptores espaciais candidatos; não chuta e não confirma resultado.

A tecla configurada não é persistente e precisa ser reinserida após reiniciar o script. `AUTO:OFF` não desarma a observação. `PASSBTN` desliga a automação para evitar alterar botão durante a tentativa.

## Limitações a validar

- O botão de passe correto e a influência dos direcionais precisam ser confirmados no jogo. A direção não é necessariamente seleção de receptor.
- Distância em linha reta não otimiza tempos de animação, precisão ou interceptações.
- A detecção espacial de posse pode produzir falso positivo; um pulso pode sair durante uma bola solta.
- Um receptor repetido não aumenta o contador candidato; isso não prova progresso oficial.
- Sem detecção segura do contexto do jogo após `ARM`, a automação não deve ser usada fora da tentativa experimental selecionada.
- Com apenas três padrões de comandos e parâmetros fixos, a versão não é um bot completo calibrado.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v06_static.py" -v`.
