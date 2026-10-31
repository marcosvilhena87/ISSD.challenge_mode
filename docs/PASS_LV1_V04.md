# PASS LV.1 v0.4 — Monitor espacial da bola e dez jogadores de linha

## Endereços fornecidos pelo operador

Coordenadas de 16 bits com sinal em WRAM:
- Bola X=0x042A, Y=0x042C.
- Goleiro da equipe X=0x052A, Y=0x052C (**excluído**).
- Dez jogadores de linha, ids 2 a 11, X=0x042A+id*0x100, Y=0x042C+id*0x100.

## Inferência experimental

A cada frame ARM, calcula as distâncias da bola aos dez jogadores. Um candidato espacial precisa ter distância bola–jogador até **24 unidades**, margem de **6 unidades** para o segundo jogador mais próximo e estar mais próximo da bola que o goleiro. O mesmo jogador precisa satisfazer a condição por **4 frames consecutivos**. Esses limiares são provisórios e exigem calibração no jogo.

Primeira posse estável: `spatial_initial_candidate`, não contabilizada como recepção. Mudança de candidato estável: `spatial_transfer_candidate`, contabilizada como destinatário candidato distinto, **não como passe confirmado**. Uma bola apenas próxima de um atleta pode gerar falso positivo. Em consequência, o contador `visited_count` não substitui o contador oficial.

O CSV `csv/pass_spatial_v04.csv` registra frame, jogadores de origem/destino candidatos, coordenadas da bola, distâncias, destinatários e planejamento por Held–Karp, exclusivamente geométrico. O CSV bruto v0.3 continua disponível.

## Como executar

1. Use `PASS` em `challenge_mode.txt` e inicie `main.lua` no BizHawk.
2. Escolha PASS LV.1 e acrescente `ARM` seguido de nova linha em `txt/pass_bot_commands_v01.txt`.
3. Faça passes manualmente entre jogadores de linha e observe `csv/pass_spatial_v04.csv`.
4. Acrescente `STOP` quando terminar.
5. Faça controles sem passes e com bola livre para estimar falsos positivos.

Nenhuma escrita em RAM e nenhum comando automático de passe. Para a próxima versão, comparar eventos inferidos com passes confirmados visualmente e com o eventual contador do jogo antes de automatizar.

Teste de integração estático (ainda exige execução no BizHawk):
`python -m unittest discover -s tests -p "test_pass_v04_static.py" -v`
