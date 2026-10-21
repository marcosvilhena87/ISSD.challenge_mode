# ISSD.challenge_mode

Reiniciado em 21/10/2026. Versão **v0.2 experimental** para International Superstar Soccer Deluxe (SNES), BizHawk + Lua.

## Mapeamento
O projeto reaproveita **somente hipóteses instrumentadas** documentadas em [ISSD.mapping/docs/CHALLENGE_MODE.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/CHALLENGE_MODE.md). Consulte [docs/MAPPING_INTEGRATION.md](docs/MAPPING_INTEGRATION.md). O `ISSD.mapping` é a fonte canônica; esta cópia local é um adaptador.

## Uso
No BizHawk, abra uma ROM obtida legitimamente e carregue `lua/main.lua` pelo console Lua, executando a partir da raiz deste repositório. O script apenas lê cinco endereços WRAM e informa `candidate` ou `unknown` quando os valores se alteram. Não envia comandos ao jogo.

**Atenção:** `candidate` não comprova que o menu Challenge Mode esteja aberto. Nenhuma flag de presença foi validada. Não usar esta saída para controle automático.

## Testes
Com Lua disponível no PATH, execute `lua tests/test_probe.lua`. Testes simulados não equivalem a validação no jogo.

## Próximas etapas
Ver [docs/ROADMAP.md](docs/ROADMAP.md) e [docs/EXPERIMENTOS.md](docs/EXPERIMENTOS.md). O histórico anterior permanece em Git.
