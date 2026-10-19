# Scanner WRAM — BizHawk/Lua

## Princípio
Exporta a WRAM inteira (128 KiB) como arquivos `.hex` e compara os 24 cenários (seis desafios × LV1–4) em **duas rodadas**. O algoritmo encontra offsets de byte e word little-endian cujos valores sejam constantes dentro do mesmo grupo e variem entre grupos. **Correlação não é validação.** O uso de `memory.read_u8(..., "WRAM")` deve ser confirmado na versão instalada do BizHawk.

## Coleta
1. Clone o projeto, mantenha o diretório de trabalho na raiz e crie a pasta `snapshots/` (já existe no Git). Abra a ROM-alvo e o **Lua Console**.
2. Carregue `lua/challenge/wram_scanner.lua` chamando `dofile("lua/challenge/wram_scanner.lua").run()`.
3. Fora do Challenge Mode, aperte **F7** uma vez para registrar o baseline. O script **não** seleciona desafios automaticamente.
4. Na seleção de desafios, vá a **DRIBBLE LV1**, aguarde a tela estabilizar e pressione **F6**. Continue na ordem indicada abaixo. Uma tecla registra o conteúdo atual da WRAM: o script não garante que você esteja na tela correta.
5. Ordem de cada rodada: `dribble`, `pass`, `shoot`, `defense`, `corner_kick`, `free_kick`; para cada modalidade capture LV1, LV2, LV3 e LV4. Depois repita todos os 24 casos em uma segunda rodada.
6. Ao concluir, feche o scanner e rode `lua tests/test_wram_analyzer.lua` e `lua lua/analyze_snapshots.lua` a partir da raiz (Lua 5.1+).

## Saída
- `snapshots/manifest.csv`: ordem, modalidade, nível e rodada declarados pelo operador.
- `snapshots/*.hex`: um snapshot hexadecimal completo por caso (~256 KiB por arquivo).
- `snapshots/candidates.csv`: endereço, largura, dimensão correlacionada, número de valores distintos e status `candidate`.

**Atenção:** captures são informações sensíveis à ROM e ao savestate; devem ficar locais e não ser commitadas. Não iniciar captura se `manifest.csv` já existe: arquive a coleta antes de recomeçar.

## Limitações e validação
- Escaneamento byte a byte gera pausa momentânea; não executa comandos de jogo.
- Capturas durante animações podem gerar falsos positivos; repita preferencialmente em estado estável.
- Apenas candidatos **constantes nas duas rodadas** são listados; variáveis codificadas dinamicamente podem ficar de fora.
- O scanner detecta correlações, não determina se a posição contém uma flag real, um espelho, uma tabela ou dados gráficos.
- Para validar um candidato, alterar modalidade/nível repetidamente, comparar valores em tempo real, testar fora do Challenge Mode e usar evidência CSV; só então atualizar `ISSD.memory_map`.
