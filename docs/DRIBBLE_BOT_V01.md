# DRIBBLE LV.1 Bot v0.1 (piloto experimental)

A primeira automação é uma **linha de base**, não uma estratégia comprovadamente vencedora. O sentido de ataque **foi suposto para X crescente**, e a condição de conclusão do objetivo não foi mapeada. O bot não consegue afirmar que concluiu o desafio. Ele grava uma trajetória para calibrar a próxima versão.

## Executar
1. Feche os demais scripts Lua. Faça `git pull --ff-only origin main`.
2. Carregue `dribble_bot.lua` sozinho no Lua Console do BizHawk. O bot inicia **DESARMADO**.
3. Abra DRIBBLE LV.1 normalmente e confirme CHALLENGE START; quando o jogador estiver em campo execute no PowerShell, na raiz do repositório:
   `Add-Content .\dribble_bot_commands_v01.txt 'ARM'`
4. O bot tenta buscar a bola quando ela estiver afastada e, caso contrário, avança para X crescente. Os comandos são aplicados ao controle 1; não executa chute, passe ou dash.
5. Para interromper em qualquer momento: `Add-Content .\dribble_bot_commands_v01.txt 'STOP'`. Parar o script Lua também interrompe sua execução; confira a liberação de botões no emulador.
6. Ele desarma automaticamente após 1800 frames emulados (~30 segundos a 60 FPS), em GS diferente de zero, referência do jogador diferente de 0x0F00 ou falha de leitura.
7. Examine `dribble_bot_trace_v01.csv` para conferir entradas enviadas e coordenadas observadas.

Comando de análise:
```powershell
Import-Csv .\dribble_bot_trace_v01.csv |
 Select-Object -Last 40 frame,armed,reason,gs,ptr,poss,player_x,player_y,ball_x,ball_y,buttons |
 Format-Table -AutoSize
```

**Restrições:** os bytes `0x00BA` e `0x1ACC` são apenas indicadores candidatos de gameplay no Challenge Mode. Não há reconhecimento autônomo de tela, direção de gol, obstáculos ou condição de vitória. A função `joypad.set(buttons,1)` depende do mapeamento do controle SNES no BizHawk; verifique no Input Display se as entradas são recebidas. O bot não modifica RAM. Os eventos preexistentes no arquivo são ignorados quando reinicia o script. Teste sintético: `lua tests/test_dribble_bot.lua`.
