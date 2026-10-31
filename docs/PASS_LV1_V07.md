# PASS LV.1 v0.7 — Chute automático experimental

**Comandos confirmados pelo operador:** passe = botão B; chute = botão X. **Não foi validada direção de mira do gol, nem a detecção do gol.** O chute v0.7 é um único pulso X sem direção. Não proclama vitória nem pontuação.

## Instruções

Na raiz do repositório, configure `challenge_mode.txt` como `PASS`. Inicie `main.lua` no BizHawk. Depois de entrar manualmente no PASS LV.1, acrescente ao `txt/pass_bot_commands_v01.txt`, uma linha por vez:

```text
PASSBTN:B
AUTO:ON
FINISH:ON
ARM
```

- `FINISH:ON` habilita somente a próxima tentativa ARM; `FINISH:OFF` cancela.
- `AUTO:OFF` desliga os passes automáticos e a finalização; `STOP` desarma e libera os botões.
- O chute exige 10 receptores **espaciais candidatos** e primeiro decréscimo observado do bônus depois desse marco. Isso é correlação, não confirmação da conclusão oficial.
- Após esses dois sinais, libera o controle e aciona X por um frame, uma única vez.
- Expira se mais de 180 frames decorrerem após o decréscimo ou 240 após a conclusão candidata. Sem sinal de bônus, não chuta.
- A intenção é experimental e conservadora; nenhum direcionamento automático comprovado ao gol nesta versão.
- Eventos em `csv/pass_finish_v07.csv`. Não existe validação automática do gol.

## Testar

`python -m unittest discover -s tests -p "test_pass_v07_static.py" -v`

No BizHawk, testar primeiro uma sessão controlada com gravação de `pass_auto_v06.csv`, `pass_spatial_v04.csv`, `pass_bonus_validation_v051.csv` e `pass_finish_v07.csv`. Comparar visualmente a direção do chute e confirmar o botão X. Se necessário, usar `FINISH:OFF` e `STOP`. Não mesclar com main antes de validação.
