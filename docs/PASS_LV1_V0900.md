# PASS LV.1 — v0.9.0: finalização após 10/10 espacial

Base: v0.8.99. Não modifica a lógica que conseguiu atingir dez jogadores; altera apenas `lua/challenge/pass_finish_v07.lua` e a instrumentação de finalização em `lua/pass_bot.lua`.

Após a contagem 10/10 e a primeira redução de bônus correspondente, a aproximação ao gol agora permite no máximo **210 frames**, contra 120 anteriormente. O prazo de observação de conclusão foi ampliado de 180/240 para 330/390 frames a partir do bônus/conclusão. O limite de distância para emitir X permanece **135 WRAM** no eixo horizontal: não se força chute quando está longe.

Se a distância horizontal ao gol não diminuir ao menos 0,5 WRAM por 15 frames, alterna modo de caminhada: diagonal, horizontal e vertical (este somente quando houver desvio vertical), limitando a nove recuperações; após isso registra `shot_blocked_no_progress`. Os botões de aproximação são mantidos separados de X e B. A validação de bola aos pés do portador permanece obrigatória.

Telemetria: `finish_goal_approach` inclui distância atual, dx, dy, modo e botões direcionais; `finish_approach_recovery` relata recuperação; `finish_x_output` registra o comando X efetivamente montado com os demais botões. O monitor passivo de evidências de gol permanece ativo após X.

**Não há confirmação de sucesso oficial do jogo até que a execução real mostre gol e evidência suficiente.** O posicionamento do gol/ataque continua com referências WRAM sujeitas a calibração.
