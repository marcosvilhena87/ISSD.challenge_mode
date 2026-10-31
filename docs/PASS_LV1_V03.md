# PASS LV.1 v0.3 — Monitor de posse (experimental)

O script `lua/pass_bot.lua` agora inclui monitoramento independente de mudanças estáveis em um valor candidato de posse, sem realizar passes automaticamente.

## Estado da evidência

- O endereço WRAM `0x00A6` (16 bits little-endian) é conhecido do projeto DRIBBLE, **não validado para PASS LV.1**.
- A transferência manual observada nas capturas anteriores comprova o evento visual, mas não a semântica de `0x00A6`.
- O monitor exige três amostras consecutivas com o mesmo valor antes de registrar `initial_stable_value` ou `stable_value_change`.
- Uma alteração estável indica apenas mudança de valor, não uma recepção validada, não um passe bem-sucedido e nem a identidade do jogador.
- Se `pass_ram_map_v02.lua` estiver presente e for válido, o monitor usa o endereço/bitwidth e os valores de identidade cadastrados, ainda sujeitos a confirmação. Caso contrário usa a hipótese `0x00A6` somente para observação.
- Sem configuração validada o arquivo de rastreamento v0.2 dos dez jogadores permanece sem recepções identificadas; o monitor v0.3 ainda registra transições brutas.

## Experimento

1. Em `challenge_mode.txt`, escolha `PASS` e abra `main.lua` no BizHawk.
2. Entre em PASS LV.1. Acrescente `ARM` e uma quebra de linha a `txt/pass_bot_commands_v01.txt`.
3. Realize passes manuais entre jogadores de linha e, quando útil, capture `SNAP:ANTES` e `SNAP:DEPOIS`.
4. Examine `csv/pass_possession_v03.csv`: `previous_raw`, `current_raw`, `player_id`, `source`, `confidence`.
5. Use `STOP` para encerrar a tentativa. Execute controles negativos sem passe e compare também com pausa, bola solta e jogadas envolvendo o goleiro.

## Próxima validação

Registrar ao menos três transferências de posse confirmadas visualmente, relacionando valores brutos observados e jogadores visíveis. Somente após controles independentes estabelecer o mapa de slots/entidades, excluir os goleiros e inferir recepções por destinatário. O planejamento geométrico Held–Karp da v0.2 permanece disponível com mapa configurado.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v03_static.py" -v`.

A análise no BizHawk continua obrigatória: o teste estático não valida RAM e não substitui testes de execução Lua.
