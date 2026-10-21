# Reconhecedor contextual v0.4 (experimental)

Executar `lua/main.lua` no console Lua do BizHawk. Mantem `challenge_transitions_v03.csv` e `operator_events_v03.txt`; adiciona `challenge_context_v04.csv`.

O operador deve registrar as mudancas VISUAIS no PowerShell, a partir da raiz do repositorio:

```powershell
Add-Content .\operator_events_v03.txt 'main_menu'
Add-Content .\operator_events_v03.txt 'mode_selection'
Add-Content .\operator_events_v03.txt 'input_name'
Add-Content .\operator_events_v03.txt 'challenge_selection'
Add-Content .\operator_events_v03.txt 'level_select'
Add-Content .\operator_events_v03.txt 'playing'
Add-Content .\operator_events_v03.txt 'pause'
```

Enviar apenas o evento que descreve a tela visivel no momento, logo apos ela aparecer. Eventos historicos sao ignorados ao iniciar o monitor. `menu` continua aceito por compatibilidade, mas e ambiguo e nao ativa classificacao contextual.

A v0.4 diferencia, exclusivamente em contexto ROTULADO:
- `mode_selection`: b=255, cursor 0 Training / 1 Challenge.
- `input_name`: cursor bruto; nao pressupor quantidade total de teclas.
- `challenge_selection`: a=5, b=0, cursor 0..5 modalidades, 6 EXIT.
- `level_select`: a=b em 0..5; cursor 0..3 equivale LV1..LV4.

**Limites:** rotulos do operador sao evidencias manuais e nao uma flag de menu independente. Os mesmos bytes aparecem em outras telas. `candidate` nao significa confirmado. Sem rotulo confiavel, mantem `unknown`. Registros invalidos (por exemplo indices 4 e 5 em `level_select`) ficam `unknown`; nao existem LV5 ou LV6 validados. O monitor nao envia controles ao jogo.

Testes: `lua tests/test_probe.lua`, `lua tests/test_monitor.lua`, `lua tests/test_context.lua`. Todos sinteticos; validar no BizHawk com ROM identificada e controles negativos antes de promover hipoteses em `ISSD.mapping`.
