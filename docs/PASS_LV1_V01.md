# PASS LV.1 — v0.1: base observacional

## Escopo

O modo `PASS` no `challenge_mode.txt` inicia `lua/pass_bot.lua`, sem alterar o DRIBBLE.
A primeira fase é **observacional**: não pressiona botões de passe nem escreve em RAM.
Ainda não foram validados os endereços dos jogadores, bola, alvo, pontuação, cronômetro ou resultado do PASS LV.1.

## Uso no BizHawk

1. Selecione manualmente o desafio PASS LV.1 no jogo.
2. Crie `challenge_mode.txt` (UTF-8/ASCII) com `PASS` e inicie `main.lua`.
3. Após iniciar, acrescente `ARM` seguido de uma quebra de linha em `txt/pass_bot_commands_v01.txt`.
4. Para encerrar a captura, acrescente `STOP` seguido de quebra de linha.
5. Examine `csv/pass_lv1_observations_v01.csv` para mudanças de estado.

**Importante:** o monitor identifica apenas candidatos com base em bytes hipotéticos, não confirma a tela ou o resultado. O comando ARM só é aceito caso a leitura seja candidata PASS nível 1. A observação continua independentemente de ARM, e `STOP` desarma, mas não encerra o Lua. Não interprete `armed_candidate_only` como início ou sucesso confirmado.

## Etapas seguintes antes da automação

- Capturar sessões independentes: menu PASS LV.1, jogo, pausa, conclusão, falha e DRIBBLE controle.
- Comparar diferenças RAM e validar identidades/posições de passador, receptor e bola.
- Identificar botão e duração de passe com experimento isolado.
- Validar contador de passes, temporizador e condição de vitória com repetição e controles negativos.
- Somente então implementar controlador de passe com liberação segura de botões e testes sintéticos.

## Testes estáticos

`python -m unittest discover -s tests -p 'test_pass_entrypoint.py'`

Os testes não substituem a validação experimental com ROM/BizHawk.
