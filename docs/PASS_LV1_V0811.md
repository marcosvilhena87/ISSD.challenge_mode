# PASS LV.1 v0.8.11 — experimento controlado de acionamento

Objetivo: diferenciar erro de comando e posse inferida cedo demais. A estratégia de destinatários e os passes de apoio da v0.8.10 são preservados.

## Modos de acionamento

- `TRIGGER:A` — sem espera adicional; mesmos dois frames máximos de alinhamento e três frames de direcional + B.
- `TRIGGER:B` — após selecionar um receptor, espera **12 frames neutros**, sem pressionar direcional ou B; em seguida executa exatamente o mesmo alinhamento e passe.
- O modo deve ser escolhido **antes** de `ARM` e é aplicado a cada passe da cadeia.
- Não ativa chute X nem faz escrita de RAM. Um erro de passe continua encerrando a cadeia com segurança.

## CSV de diagnóstico

`csv/pass_trigger_v0811.csv`: sessão, frame, modo, fase, portador, alvo, coordenadas da bola, coordenadas do portador inferido, distância bola-portador e botões enviados. É registrado a cada frame durante `prewait`, `align`, `hold` e os primeiros 30 frames de `wait`.

O relatório mede **proximidade**, não confirma que a ROM atribuiu posse ao jogador.

## Comparação reproduzível

1. Carregue um mesmo **savestate** no início do PASS LV.1, no mesmo frame, e reinicie `main.lua`.
2. Com PowerShell aberto no diretório do projeto, rode o modo A:

```powershell
@("TRIGGER:A","PASSBTN:B","DIRECTION:AUTO","AUTO:ON","ARM") |
  Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

3. Guarde os CSVs da sessão. Recarregue **exatamente o mesmo savestate**, reinicie `main.lua` e rode o modo B:

```powershell
@("TRIGGER:B","PASSBTN:B","DIRECTION:AUTO","AUTO:ON","ARM") |
  Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

4. Compare `pass_trigger_v0811.csv`, `pass_inputs_v081.csv`, `pass_auto_v06.csv` e o vídeo do BizHawk, especialmente o primeiro movimento e o resultado `no_ball_motion_detected`.

O tempo de leitura do arquivo de comandos pode variar entre sessões. Para comparação rigorosa, conferira o frame de ARM, o frame de B e o estado inicial no log. Os testes estáticos não substituem a execução real.
