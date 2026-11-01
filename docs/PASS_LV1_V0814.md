# PASS LV.1 v0.8.14 — orientação antes do passe

O problema observado no emulador: o tempo acabou enquanto o portador estava de costas para os companheiros, e o jogo não reconheceu uma recepção. A nova rotina procura **virar o jogador em direção ao destinatário antes de pressionar B**.

## Sequência

1. Seleciona o destinatário usando a estratégia da v0.8.10 e aguarda a barreira de estabilidade de posse da v0.8.12.
2. Caso TRIGGER:B esteja habilitado, espera também os 12 frames neutros do experimento.
3. **Orientação:** mantém apenas uma direção *cardinal* em direção ao destinatário por 4 frames. Recalcula a direção conforme as coordenadas mudam. Não envia B.
4. **Soltura:** 1 frame neutro para separar a orientação do passe.
5. Mantém até 2 frames de correção direcional da versão anterior, quando aplicável.
6. Pressiona direcional + B simultaneamente por 3 frames, sem X; observa a recepção como antes.

A rotina é geométrica; **não existe endereço RAM validado que confirme para onde o sprite está olhando**. Quatro frames é um parâmetro experimental, não uma garantia. Como um jogador pode se deslocar enquanto vira, a barreira de posse ocorre antes da orientação; deve-se monitorar se esse movimento afasta o jogador da bola.

## Auditoria e execução

Eventos `facing_directional` e `facing_release` são registrados em `csv/pass_auto_v06.csv`. O `csv/pass_trigger_v0811.csv` registra os inputs, incluindo a fase `face`.

```powershell
@("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","FINISH:ON","AUTO:ON","ARM") |
 Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

Finalização X continua condicional a FINISH:ON, 10/10 e decremento do bônus, nunca simultânea ao B.

Compare deslocamento após o B, `ball_moved_without_transfer`, número de participantes e tempo restante, a partir do mesmo savestate. Sem validação no BizHawk.
