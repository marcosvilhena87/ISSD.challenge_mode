# Scanner WRAM — BizHawk/Lua

## Princípio
Exporta a WRAM inteira (128 KiB) como arquivos `.hex` e compara os 24 cenários (seis desafios × LV1–4) em **duas rodadas**. O algoritmo encontra offsets de byte e word little-endian cujos valores sejam constantes dentro do mesmo grupo e variem entre grupos. **Correlação não é validação.** O uso de `memory.read_u8(..., "WRAM")` deve ser confirmado na versão instalada do BizHawk.

## Coleta
1. Abra a ROM no BizHawk e carregue `lua/start_scanner.lua` no Lua Console.\n2. O scanner cria automaticamente `snapshots/session_AAAAMMDD_HHMMSS/` (sufixos numéricos evitam colisões). Coletas anteriores não são apagadas.\n3. Fora do Challenge Mode, aperte **F7** uma vez para registrar o baseline. O script **não** seleciona desafios automaticamente.
4. Na seleção de desafios, vá a **DRIBBLE LV1**, aguarde a tela estabilizar e pressione **F6**. Continue na ordem indicada abaixo. Uma tecla registra o conteúdo atual da WRAM: o script não garante que você esteja na tela correta.
5. Ordem de cada rodada: `dribble`, `pass`, `shoot`, `defense`, `corner_kick`, `free_kick`; para cada modalidade capture LV1, LV2, LV3 e LV4. Depois repita todos os 24 casos em uma segunda rodada.
6. Ao concluir, feche o scanner e rode `lua tests/test_wram_analyzer.lua` e `lua lua/analyze_snapshots.lua` a partir da raiz (Lua 5.1+), após `cd "C:\Minha_Pasta\Jogos\BizHawk-2.11.1-win-x64\ISSD.challenge_mode-main"` no PowerShell.

## Saída
- `snapshots/session_AAAAMMDD_HHMMSS/manifest.csv`: ordem, modalidade, nível e rodada declarados pelo operador.
- `snapshots/session_AAAAMMDD_HHMMSS/*.hex`: um snapshot hexadecimal completo por caso (~256 KiB por arquivo).
- `snapshots/session_AAAAMMDD_HHMMSS/candidates.csv`: endereço, largura, dimensão correlacionada, número de valores distintos e status `candidate`.

**Atenção:** captures são informações sensíveis à ROM e ao savestate; devem ficar locais e não ser commitadas. Cada nova execução inicia uma sessão distinta; arquivos antigos na raiz de `snapshots/` permanecem intactos.

## Limitações e validação
- Escaneamento byte a byte gera pausa momentânea; não executa comandos de jogo.
- Capturas durante animações podem gerar falsos positivos; repita preferencialmente em estado estável.
- Apenas candidatos **constantes nas duas rodadas** são listados; variáveis codificadas dinamicamente podem ficar de fora.
- O scanner detecta correlações, não determina se a posição contém uma flag real, um espelho, uma tabela ou dados gráficos.
- Para validar um candidato, alterar modalidade/nível repetidamente, comparar valores em tempo real, testar fora do Challenge Mode e usar evidência CSV; só então atualizar `ISSD.memory_map`.
