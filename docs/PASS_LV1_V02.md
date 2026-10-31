# PASS LV.1 v0.2 — identificação experimental e roteamento

**Estado:** código de rastreamento e planejamento implementado; **nenhum endereço de jogador, goleiro ou posse de bola foi validado na ROM**. Por isso, o rastreamento fica desligado até que um mapa local seja fornecido.

## Configuração local

Crie na raiz `pass_ram_map_v02.lua` contendo uma tabela Lua nesse formato (substitua TODOS os valores pelos endereços e identificadores comprovados na sua ROM; os valores abaixo são apenas marcadores e não devem ser copiados como mapa válido):

```lua
return {
  possession_address = 0x0000, -- SUBSTITUIR: endereço RAM da posse
  possession_width = 16, -- 8 ou 16; validar em experimento
  no_possession_values = {-1}, -- SUBSTITUIR: valores sem posse
  players = {
    -- São exatamente dez jogadores de linha, sem goleiro.
    -- {id=1, possession_value=1, x_address=0x0000, y_address=0x0002},
    -- ... repetir até id=10 com endereços únicos e comprovados.
  },
}
```

Não use esse exemplo sem calibração. O leitor exige exatamente dez jogadores e não aceita repetição de IDs ou valores de posse; não consegue, porém, confirmar por si que um slot é realmente de jogador de linha. Deve-se verificar identidade de cada um, goleiro e quadro de equipe por sondagem experimental e controles negativos.

Execute `challenge_mode.txt` com `PASS`. Com PASS LV.1 selecionado, adicione `ARM` seguido de quebra de linha em `txt/pass_bot_commands_v01.txt`. `STOP` encerra a tentativa. Logs: `csv/pass_lv1_tracking_v02.csv` (somente com mapa configurado, válido e leitura bem-sucedida).

## Telemetria e limites

- Aguarda três amostras consecutivas do mesmo portador antes de registrar mudança.
- `initial_possession`: primeira posse estável, **não** significa recepção.
- `transfer_candidate`: troca estável de portador identificada; incrementa destinatários únicos, **sem comprovar que o desafio validou o passe**. A perda de posse, o goleiro, a interceptação, a origem da bola e a confirmação do jogo permanecem pendentes.
- `visited_count`: número de receptores distintos **candidatos**, não um contador oficial da ROM.
- `planned_route`: sequência estimada pelo algoritmo exato Held–Karp, minimizando distâncias em linha reta entre os receptores ainda não visitados a partir do atual portador.
- `confidence=unverified_ram_candidate`: aviso de que a configuração e os eventos ainda exigem confirmação independente.
- O algoritmo não incorpora duração das animações, interceptações, movimento dos jogadores ou escolha física do passe, portanto **não prova a rota mais rápida em frames**.
- Nenhuma tecla de passe é enviada; o joypad permanece neutro. Nenhuma escrita em RAM.

## Critérios de promoção a validado

1. Capturar em CSV posição/slot e posse candidatos com estados repetidos, pausas e controles negativos.
2. Confirmar visualmente que cada slot corresponde a um dos dez jogadores de linha e que não inclui o goleiro.
3. Validar sequência de posse em ações isoladas, incluindo reposse, interceptações, passes errados e passes bem-sucedidos.
4. Correlacionar contador de destinatários e bônus oficial, se identificado, com a lista inferida.
5. Medir tempos reais em frames de diferentes sequências de passe para escolher a rota mais rápida **observada**, não apenas a menor distância.

## Testes

`python -m unittest discover -s tests -p 'test_pass_v02_static.py'`

Testes estáticos não substituem execução de Lua no BizHawk.
