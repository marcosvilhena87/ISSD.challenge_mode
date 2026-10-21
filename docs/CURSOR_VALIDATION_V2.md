# WRAM Cursor Validation v2

Sondagem independente, somente leitura, do endereco candidato `0x01542` (WRAM, u8). A origem e a descoberta v1, mas o endereco **nao esta validado**. O programa nao envia inputs, nao modifica WRAM, nem altera `ISSD.mapping`.

## Executar

1. Feche os outros scripts Lua do BizHawk.
2. Execute `cursor_validation.lua` da raiz do projeto. O script imprime os caminhos completos relativos a raiz para `cursor_validation_events_v2.txt` e `cursor_validation_v2.csv`.
3. Na tela CHALLENGE START, com a primeira opcao destacada, envie `Add-Content .\\cursor_validation_events_v2.txt 'A'`.
4. Mova visualmente para CHANGE CONTROLLER e envie `Add-Content .\\cursor_validation_events_v2.txt 'C'`.
5. Mova visualmente para KEY CONFIGURATION e envie `Add-Content .\\cursor_validation_events_v2.txt 'B'`.
6. Volte a CHALLENGE START e envie `Add-Content .\\cursor_validation_events_v2.txt 'A'`.
7. Para controles negativos, entre em outras telas e anote seus rotulos, por exemplo `MAIN_MENU`, `CHALLENGE_SELECTION`, `LEVEL_SELECT`, `INPUT_NAME`, `PLAYING`, `PAUSE`. Registre a transicao visual em cada tela no momento adequado. O programa **nao** presume que valores repetidos nessas telas sejam exclusivos do submenu.

O monitor registra todos os eventos aceitos e alteracoes detectadas no valor amostrado, com frame, rotulo, valor, valor esperado para A/B/C, correspondencia e avaliacao. A primeira linha da sessao e `initial/UNLABELED`. Eventos preexistentes sao ignorados ao iniciar. Os rotulos do operador nao sao detectores independentes da tela. O campo `match=yes` apenas confirma concordancia com uma hipotese e nunca significa reconhecimento validado.

Valores esperados sob teste: A=0, C=2, B=1, A=0. Outras codificacoes sao possiveis. Repita com o cursor em ordem diferente e em uma sessao independente; compare os frames e opcoes visuais. Sao necessarios controles negativos antes de promover o resultado em `ISSD.mapping`.

### Teste sintetico
`lua tests/test_cursor_validation.lua`

Saidas locais (ignoradas pelo Git): `cursor_validation_events_v2.txt` e `cursor_validation_v2.csv`. Nao comitar ROM nem dumps.
