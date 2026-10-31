# PASS LV.1 v0.5 — Timer e sincronização espacial

O runner `lua/pass_bot.lua` usa os endereços de timer do DRIBBLE como hipóteses aplicáveis ao PASS LV.1.

| Endereço WRAM | Tipo | Hipótese |
|---|---|---|
| `0x014F0` | byte BCD | tempo principal |
| `0x014F2` | word | fração do tempo |
| `0x014F4` | byte BCD | bônus |
| `0x014F6` | word | fração do bônus |

O arquivo `csv/pass_timers_v05.csv` recebe eventos `main_time_change`, `bonus_value_change` e `bonus_zero_to_positive_candidate`, correlacionados com o contador de receptores espaciais **candidatos**, o frame do último evento espacial e a diferença em frames.

**Atenção:** o formato real do gatilho do bônus não foi estabelecido. A detecção zero→positivo é apenas uma hipótese e pode nunca acontecer caso o contador comece positivo, diminua ou use outro mecanismo. Este observador não confirma conclusão de 10 jogadores. A leitura BCD recusa bytes inválidos; as frações são valores brutos, sem conversão para segundos. Em modo não armado não há eventos; ao armar, o estado do observador é reiniciado.

## Experimento no BizHawk

1. Atualize a branch e inicie `main.lua` em modo `PASS`.
2. Selecione PASS LV.1 e acrescente `ARM` em `txt/pass_bot_commands_v01.txt`.
3. Passe manualmente para os jogadores de linha e complete a etapa dos dez destinatários.
4. Registre visualmente o frame de ativação do bônus e compare com `pass_timers_v05.csv` e `pass_spatial_v04.csv`.
5. Repita com uma sessão incompleta e uma sessão sem passes, como controles negativos.

A automação do passe, o contador oficial de recepções e o estado do chute não foram implementados. Nenhuma escrita em RAM é realizada.

Testes estáticos (não executam o jogo): `python -m unittest discover -s tests -p "test_pass_v05_static.py" -v`.
