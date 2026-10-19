# Reconhecimento WRAM experimental (v0.3)

Os enderecos abaixo foram observados em duas sessoes com 24 cenarios cada:

| Campo | Par A | Par B | Codificacao |
| --- | --- | --- | --- |
| challenge | WRAM 0xD708 | WRAM 0xE52C | 0=dribble, 1=pass, 2=shoot, 3=defense, 4=corner_kick, 5=free_kick |
| level | WRAM 0xD70A | WRAM 0xE52E | 0=LV1, 1=LV2, 2=LV3, 3=LV4 |

O runtime `lua/main.lua` le os quatro bytes atraves de `memory.read_u8(address, "WRAM")`. Se os pares concordam, estao nos intervalos esperados e permanecem iguais por pelo menos tres frames, ele emite:

```
[ISSD.challenge_mode] candidate challenge=dribble level=1 source=candidate_wram reason=mode_not_validated
```

Se houver divergencia, ausencia de dados ou valor fora dos intervalos, emite `unknown`. Uma observacao manual explicita pode ser usada separadamente e tem precedencia.

**Nao considerar `candidate` como detecao comprovada do Challenge Mode.** Valores espelhados ou retidos na WRAM podem existir em menus e partidas normais. Antes de promover o status para `identified`, testar em tempo real a transicao entre menus, as seis modalidades, os quatro niveis, o retorno ao menu principal e partidas normais, com registro da ROM/hash e evidencias negativas.

## Execucao

Abra a ROM no BizHawk, depois `lua/main.lua` no Lua Console. O scanner de capturas usa um script separado, `lua/start_scanner.lua`. Evite executar os dois simultaneamente durante calibracao.

## Teste unitario

A partir da raiz do projeto:

```powershell
lua tests/test_memory_probe.lua
lua tests/test_recognizer.lua
```

Os testes exercitam a logica pura; nao substituem um ensaio dentro do BizHawk.
