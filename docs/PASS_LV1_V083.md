# PASS LV.1 v0.8.3 — integração do seletor com o controlador

Esta versão foca o defeito em que o seletor registrava `selected`, mas o controlador recebia `no_valid_target`.

## Verificação no início

- Recarrega os módulos experimentais de seleção, ponte e controlador ao iniciar `main.lua`, reduzindo risco de cache antigo no mesmo estado Lua.
- Imprime `selector_version=0.8.3 selector_api=3 bridge=0.8.3`.
- Executa um teste de integração **em Lua** com portador 6 e nove receptores elegíveis, verificando escolha válida, aceitação em `Auto.step()`, simultaneidade direcional+B em três frames e apenas um pulso.
- Falha de autoteste impede o envio de controle automático, mas mantém a observação.

## Telemetria

O evento `handoff_diagnostic` em `csv/pass_auto_v06.csv` contém versão do módulo, resposta do seletor, `receiver.id` e `plan.target`. O CSV `pass_candidates_v082.csv` continua registrando candidatos e métricas.

## Execução no PowerShell

Na pasta do projeto, reinicie `main.lua` em PASS LV.1 e execute:

```powershell
@(
  "PASSBTN:B"
  "DIRECTION:AUTO"
  "AUTO:ON"
  "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

O passe permanece **experimental**, com um único comando por ARM, Control Pad e B no mesmo frame e finalização X desabilitada. `STOP` solta os controles.

Testes estáticos: `python -m unittest discover -s tests -p "test_pass_v083_static.py" -v`. O teste Lua de integração é acionado pelo boot no BizHawk; ainda não há validação real nesta publicação.
