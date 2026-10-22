## Collection Zone Discovery v3 — controlled flag 2 entry experiments

Default is `ZONE:OFF` (old route unchanged). Commands `ZONE:LEFT`, `ZONE:ABOVE`, `ZONE:BELOW`, `ZONE:OFF` are read from the bot's command file and applied on the next `ARM`. Only flag 2 gets an experimental staging waypoint at offsets (-42,0), (-42,-22), or (-42,+22) from its configured waypoint. Upon reaching the staging region (+/-9 on both coordinates), the controller resumes steering to the original waypoint. Existing precision, ball recovery, shot and result observation remain unchanged; Y Dash stays off. Staging coordinates are hypotheses, not collision-zone boundaries. Collection transitions for flag 2 record chosen mode, pre/post positions and cumulative travel into `dribble_collection_zone_v3.csv` (consolidated into `dribble_diagnostics_v2.csv` in COMPACT). Original v2 transition and negative evidence are kept. Test: `tests/test_dribble_collection_zone_v3.lua`. Confirm real behavior in BizHawk; compare repeated runs under controlled starting conditions.

## Route Optimization v2 — Collection Zone Discovery (observation only)

The new pure module `lua/challenge/dribble_collection_zone_v2.lua` observes individual flag-counter transitions (exactly -1 on contiguous frames), capturing the final position before the transition, the first position after it, up to 12 frames of preceding coordinates, and distance to the existing waypoint. It also records sparse `near_without_transition` observations within 30 units (every 15 frames per flag) as negative evidence. Events are consolidated into the existing `dribble_diagnostics_v2.csv` in COMPACT mode; FULL mode writes `dribble_collection_zone_v2.csv`. These samples are evidence of candidate collection entry positions, **not** proven collision boundaries or verified centers. Counter jumps and frame gaps are rejected. All movement, waypoints, `ROUTE:` policy and goal detection remain unchanged, and Dash remains off. Synthetic test: `tests/test_dribble_collection_zone_v2.lua`.

## Route Optimization v1 (experimental)

Dash permanece desativado. A referencia de toda a rota permanece `DIRECT_LINE`, mas a bandeira 2 aceita um experimento reversivel pelo arquivo de comandos do bot: `ROUTE:DIRECT_LINE`, `ROUTE:DIAGONAL_FIRST` ou `ROUTE:COLLECTION_ENTRY`, aplicado no proximo `ARM`. A primeira politica preserva a orientacao historica; a segunda combina eixos em direcao ao waypoint; a terceira mira um ponto experimental 8 unidades antes do waypoint X da bandeira 2 (nao confundir com area de coleta validada). No trecho de aproximacao, busca, recuperacao da bola ou chute, o controlador original continua decidindo os botoes. Medimos por bandeira deslocamento Euclidiano acumulado amostrado a cada frame, frames decorridos, numero de amostras e posicao de coleta; o arquivo `dribble_route_optimization_v1.csv` integra `dribble_diagnostics_v2.csv` no modo COMPACT. Comparacoes confiaveis exigem tentativas repetidas, idealmente de estados identicos. Teste: `tests/test_dribble_route_optimization_v1.lua`.

## DIRECT_LINE Calibration v2 (sem Dash)

No DRIBBLE LV.1, `DIRECT_LINE` agora permite movimentos diagonais simultaneos (Right+Up, Right+Down, Left+Up, Left+Down) a caminho do waypoint, corrigindo o desvio da reta por um ponto de mira projetado a frente. A zona de precisao, recuperacao, busca e chute permanecem independentes e Y continua desligado. `lua/challenge/dribble_direct_line_calibration_v2.lua` mede erro perpendicular, maior erro, media, frames de correcao, comandos diagonais, comandos axiais e observacoes fora do segmento. Eventos de coleta e amostras a cada 15 frames entram no CSV consolidado no modo COMPACT; em FULL ficam em `dribble_direct_line_calibration_v2.csv`. Execute `tests/test_dribble_direct_line_v2.lua` no Lua Console. A geometria e o desempenho ainda precisam de validacao no jogo.

## Dribble LV.1 - orientação reta bandeira a bandeira (Dash suspenso)

A partir desta alteração o bot usa `DIRECT_LINE` por padrão, orientando deslocamentos de longo alcance pelo segmento entre a posição inicial de cada etapa e o waypoint atual; ajustes perpendiculares mantêm a proximidade da reta. Ao mudar o contador de bandeiras, a linha é reinicializada para o próximo destino. Dentro da zona de precisão, busca local, recuperação da bola e chute, a política preexistente continua responsável pelas decisões. O `Dash (Y)` está temporariamente **desligado incondicionalmente** no controlador, mesmo se a distância for grande. Seus módulos v1-v3 permanecem preservados para futura calibração. O comando `TRAVEL:AXIS` permite comparar com a navegação anterior na próxima ativação, e `TRAVEL:DIRECT_LINE` restaura o modo reto. A atribuição do perfil selecionado no ARM também foi corrigida. Os três CSVs compactos e o detector permanecem inalterados. Teste sintético novo em `tests/test_dribble_direct_line_v1.lua`. A trajetória precisa ser verificada no BizHawk antes de considerá-la calibrada.

## Dash Calibration v3

A politica de Dash da v2 e mantida. A nova instrumentacao registra as causas exatas de desligamento (`braking_distance`, `ball_gap`, `possession`, `no_direction`, `context_exit`, `precision_approach` etc.), a menor distancia ao waypoint e o intervalo desde o ultimo desligamento ate a coleta da bandeira. O registro `flag_collected` e os resumos por bandeira usam `dribble_dash_calibration_v3.csv` em FULL; em COMPACT, vao para `dribble_diagnostics_v2.csv`, sem ampliar o numero de CSVs. Execute `tests/test_dribble_dash_v3.lua` no console Lua do BizHawk. A funcionalidade precisa de validacao em partida real.

## DRIBBLE Dash calibration v2 (experimental)

`challenge.dribble_dash_v2.lua` controls Y during far-field `waypoint` only, when the game context, possession, active directional command and ball proximity are valid. Dash starts at least 100 units from waypoint. Once active, measured closing speed raises the braking distance above a 60-unit floor, capped at 145 units, with 12 frames lookahead. Y is always removed in precision/recovery/search/shooting, or if the ball is over 24 units away. This is conservative heuristic calibration, not a verified physics model. The full CSV diagnostic `dribble_dash_calibration_v2.csv` is only separate in FULL mode; in COMPACT mode events and per-flag summaries join `dribble_diagnostics_v2.csv`. The per-flag summary reports dash_frames, starts and stops; events record distance, braking threshold and closing speed. Unit test: `tests/test_dribble_dash_v2.lua`. Existing result detection and shot policy remain unchanged. Compare several runs with and without Y before concluding performance gain.

## DRIBBLE LV.1: Dash (Y) conservador

O bot utiliza `challenge.dribble_dash_v1` para adicionar `Y` somente quando `reason=waypoint`, com controle direcional ativo, bola sob posse (`poss=0x0F00`), bola ate 24 unidades do jogador e distancia ao proximo waypoint de pelo menos 100 unidades. O Y e removido durante precision_approach, local_search, recover_ball, stuck_recovery, goal_approach e todas as etapas de chute. A estrategia de rota, chutes e classificacao de gol nao muda. O trace no modo FULL inclui Y na lista de botoes; no modo COMPACT o trace segue desativado. Teste sintetico: `tests/test_dribble_dash_v1.lua` via Lua Console do BizHawk. A leitura de posse e a eficacia do Dash sao hipoteses a validar no jogo.

## Result Detector v2 — isolamento de tentativas

`lua/challenge/dribble_result_detector.lua` agora recusa bandeiras observadas depois da primeira saida do gameplay, encerra imediatamente tentativas que saem sem observar a quinta bandeira (`exit_before_fifth_flag`) e encerra a tentativa anterior ao detectar reentrada no gameplay (`new_game_before_resolution`), sem incorporar seus valores novos. A pontuacao preliminar exige que a tentativa permaneça fora do gameplay; o contador consecutivo e reiniciado na interrupcao para impedir reutilizacao de estado. Eventos de rejeicao aparecem em `trial_closed` e `finish_reason` dos CSVs existentes. Testes regressivos incluem separacao de epochs e reentrada antes da pontuacao estavel. Sem mudancas em movimento, chute ou confirmacao de gol; modo observacional preservado. Rodar testes no Lua Console e validar em BizHawk.

## Consolidação DRIBBLE CSV v2

No modo `COMPACT`, os tres CSVs novos sao `dribble_bot_summary_v035.csv`, `dribble_result_observer_v1.csv` e `dribble_diagnostics_v2.csv`. Este ultimo preserva os registros de diagnóstico com colunas `session,frame,source_csv,record_type,source_columns,source_values`. O campo `session` e obtido pelo nome da coluna original (e nao pela primeira posicao); se a origem nao possuir `session`, usa a tentativa ativa. O `frame` prioriza as colunas de frame originais e utiliza o frame corrente como fallback. O CSV audit de perfil (`frame,event,...`) deixa de ser confundido com ID de tentativa. `source_columns` e `source_values` permanecem escapados em CSV para permitir a reconstrucao dos dados originais. O modo `FULL` continua gravando os mesmos CSVs legados, incluindo trace. `dribble_diagnostics_v1.csv` nao e apagado; o novo arquivo v2 evita conflitos com esquemas preexistentes. Nenhuma mudanca na logica de jogo. O comportamento requer validacao no BizHawk.

## Arquivos TXT do projeto

A pasta `txt/` centraliza os arquivos de comandos TXT criados durante a operacao. Em novas instalacoes, o bot utiliza `txt/dribble_bot_commands_v035.txt` para receber `ARM`, `STOP` e outros comandos. Para preservar sessoes anteriores, se esse arquivo ainda nao existir, o bot continua aceitando `dribble_bot_commands_v035.txt` na raiz. A pasta e criada automaticamente quando o bot inicia; nao e necessario mover arquivos existentes. Configure os TXT `challenge_mode.txt`, `dribble_csv_mode.txt` e `score_csv_mode.txt` na raiz, pois sao configuracoes e nao arquivos gerados. O bot imprime o caminho efetivamente selecionado no console. Exemplo no PowerShell para novas instalacoes: `Add-Content .\\txt\\dribble_bot_commands_v035.txt "ARM" -Encoding ASCII`. Arquivos de log CSV continuam em `csv/`.

## SCORE_PROBE CSV mode: COMPACT (default) / FULL

The 26 historical files in the supplied score archive remain untouched. The current v3.4 probe previously emitted five CSV files. In COMPACT (default), new output is limited to **two** files: `csv/score_auto_trials_v34.csv` (unchanged summary columns) and `csv/score_diagnostics_v1.csv` (all event, primary transition, early result, and late-copy rows multiplexed with original `source_csv`, `source_columns` and escaped `source_values`). The latter preserves every underlying record for analysis. Set root `score_csv_mode.txt` to `FULL` before launching `main.lua` to resume all five historical v3.4 files. Set `COMPACT` or delete the file to return to two. This is independent of `dribble_csv_mode.txt`. Old CSVs are NOT deleted or renamed. The passive detector and all result rules are unchanged.

## DRIBBLE CSV outputs: COMPACT (default) / FULL

The bot now produces **three CSVs by default**: `csv/dribble_bot_summary_v035.csv` (original summary schema, compatible with existing workflows), `csv/dribble_result_observer_v1.csv` (detector observations), and `csv/dribble_diagnostics_v1.csv` (all less-frequent diagnostic records multiplexed with `record_key,source_csv,source_columns,source_values`). The `source_columns` and `source_values` fields contain comma-delimited content inside properly quoted CSV cells; the original source filename identifies the schema. The frame-by-frame `dribble_bot_trace_v035.csv` is disabled in COMPACT. The historical CSVs are NOT deleted or migrated. To restore legacy behavior, create `dribble_csv_mode.txt` at the repository root containing `FULL` before starting `main.lua`. To switch back, set it to `COMPACT` or delete the file. FULL keeps all historical CSV output names and trace. Both modes preserve the bot's control logic and readonly detector. Detailed scripts consuming legacy subsidiary CSVs must use FULL.

## DRIBBLE Result Detector — integracao observacional

O modo DRIBBLE agora envia os snapshots a `challenge.dribble_result_detector` todos os frames, inclusive enquanto o controlador esta desarmado ou aguardando finalizacao. O detector le separadamente 0x01CF3 (time), 0x01CF8 (bonus), 0x01CFA (total) e 0x0DC06 (copia), sem afetar `P.step`, `joypad.set`, comandos, rota, classificacao de gol ou a maquina principal. O CSV `csv/dribble_result_observer_v1.csv` identifica apenas evidencias `hypothesis_only`. Nao ha conclusao automatica de gol ou sincronizacao obrigatoria da copia. Valide os logs no BizHawk; teste unitario ja existente em `tests/test_dribble_result_detector.lua`.

## Reusable DRIBBLE Result Detector (pure module)

`lua/challenge/dribble_result_detector.lua` contains the passive detection state machine without BizHawk APIs, I/O, or controller inputs. Call `local D=require("challenge.dribble_result_detector")`, `local state=D.new()`, and `local events=D.step(state,snapshot)` once per frame. Snapshot requires `frame`, `gameplay` (boolean), `remaining`, `time`, `bonus`, `total`, `copy`. Events: gameplay_start_candidate, fifth_flag_candidate, gameplay_exit_candidate, primary_change, early_result_candidate, early_candidate_superseded, late_copy_correlated, trial_closed. The sonda `lua/score_probe.lua` owns WRAM reads and CSV files. The actual bot is unchanged. Context and scoreboard addresses are experimental; never treat a detected candidate as definitive goal confirmation. Synthetic unit tests: `lua tests/test_dribble_result_detector.lua`.

## SCORE_PROBE v3.4: resultado preliminar sem aguardar copia tardia

Ative SCORE_PROBE no challenge_mode.txt e carregue main.lua. Nenhum comando manual e necessario. O monitor procura um gameplay candidato (gs=0, ptr=0x0F00), cinco bandeiras reduzidas a zero, saida desse contexto, mudanca NOVA da pontuacao principal apos a saida e 90 frames estaveis com Total = Time + Bonus. Os enderecos Time 0x01CF3 (u8), Bonus 0x01CF8 (u16le) e Total 0x01CFA (u16le) geram score_early_results_v34.csv antes de sincronizar a copia 0x0DC06. Esta so produz score_copy_evidence_v34.csv como evidencia secundaria. Mudanca posterior na pontuacao principal invalida a classificacao preliminar e inicia nova contagem. O ensaio encerra com copia correlacionada ou timeout de 1200 frames. CSVs novos: score_events_v34.csv, score_auto_transitions_v34.csv, score_early_results_v34.csv, score_copy_evidence_v34.csv, score_auto_trials_v34.csv. As leituras e a deteccao contextual permanecem HIPOTESES; nao confirmam automaticamente gols nem alteram o bot. A v3.3 fica arquivada em lua/score_probe_v33.lua. Validar no BizHawk antes de confiar no resultado.

## SCORE_PROBE v3.3 — automatico (sem comandos)

Configure somente `challenge_mode.txt` com `SCORE_PROBE`, reinicie `main.lua` e jogue normalmente. Nao e necessario criar `score_probe_commands_v33.txt`, marcar eventos, informar pontuacoes ou exportar. A sonda observa WRAM passivamente: reconhece como *candidato* a gameplay `gs==0 && ptr==0x0F00` por 10 frames, entrada com cinco bandeiras, passagem para zero restantes e saida do contexto. Apos sair, espera ate 1200 frames por uma pontuacao estavel (90 frames), aritmeticamente coerente (`total=time+bonus`) e com a copia `0x0DC06` sincronizada. So considera valor fresco quando mudou desde a ativacao; ainda assim nao prova gol nem a tela YOUR RECORD. Saidas: `csv/score_events_v33.csv`, `csv/score_auto_transitions_v33.csv` e `csv/score_auto_trials_v33.csv`. `positive_bonus_candidate`, `time_only_candidate`, `zero_score_candidate` sao classificacoes experimentais; `possible_residual`, `five_flags_unobserved`, `arithmetic_mismatch`, `not_stable` e outros statuses indicam falta de evidencia. O bot e os modos MONITOR/DRIBBLE permanecem separados. Resultados anteriores da v3.2 continuam nos CSVs antigos e o seu codigo foi preservado em `lua/score_probe_v32.lua`. Rode o jogo em pelo menos duas sessoes independentes e confira a tela visualmente para validar a deteccao.

## SCORE_PROBE v3.3 — estabilizacao do placar (ativo)

O modo `SCORE_PROBE` executa `lua/score_probe.lua` v3.3, com comandos em `score_probe_commands_v33.txt`: `START:teste01`, `MARK:GAMEPLAY`, `MARK:TRANSITION`, `MARK:RECORD`, `RESULT:teste01:151:199`, `EXPORT`. Substitua as pontuacoes pelos valores visuais reais. O processo monitora WRAM read-only e preserva os CSVs anteriores.

A v3.3 exige consistencia aritmetica `total=time+bonus`, mudança em relação ao valor marcado em GAMEPLAY, e 90 frames sem alteração da tripla de pontuação **apos** marcador TRANSITION para emitir um evento provisório em `csv/score_stable_events_v33.csv`. Na finalizacao grava `csv/score_stability_v33.csv`, comparando snapshot capturado no RECORD com score visual e ultima tupla estabilizada. `consistent_candidate` **não** prova gol, apenas compatibilidade dos dados; `possible_residual`, `not_stable_at_record`, `arithmetic_mismatch` e `visual_mismatch` ajudam a distinguir falhas. O espelho `0x0DC06` e registrado, mas nao exigido para estabilidade devido ao atraso observado. Continua comparacao entre sessoes via `score_cross_session_v33.csv` (usando EXPORT); investigacao so se confirma com sessoes independentes e controles positivo/negativo. Nenhum controle do jogador foi alterado.

## SCORE_PROBE v3.2 — evidencias antecipadas e independentes

Atualize com `git pull --ff-only origin main`, selecione `SCORE_PROBE` e reinicie `main.lua`. Comandos em `score_probe_commands_v32.txt`: `START:teste01`, `MARK:GAMEPLAY`, `MARK:TRANSITION`, `MARK:RECORD`, `RESULT:teste01:122:206`, `EXPORT` (troque scores pelos valores reais). Registre cada comando na tela correta e execute novas partidas para os casos Bonus positivo, Time-only e Zero. Repita em uma segunda execucao independente do BizHawk (novo session ID). `ABORT` descarta tentativa corrente.

Novos CSVs: `score_baseline_v32.csv` (leitura no GAMEPLAY e comparacao com record anterior), `score_early_evidence_v32.csv` (momento da primeira mudanca, indicio de residual e igualdade no RECORD), `score_cross_session_v32.csv` (linhas por tentativa para comparar sessoes). O `score_validation_v32.csv` mantem classificacao hipotetica com controles. `score_cross_session_v32.csv` e acumulativo, mas NAO concede status automaticamente: compare ao menos duas sessoes independentes para cada categoria e endereco, evitando repetir tentativas como evidencias independentes. Nenhuma classificacao comprova gol antes da tela de resultado: o momento de mudanca e somente um indicio temporal, e valores residuais podem confundir. Os CSVs antigos continuam preservados. Os quatro enderecos principais sao 0x01CF3 (Time u8), 0x01CF8 (Bonus u16le), 0x01CFA (Total u16le) e 0x0DC06 (Total u16le), todos experimentais.

## SCORE_PROBE v3.1 — tentativas isoladas, validacao no marcador RECORD

O modo `SCORE_PROBE` do `main.lua` agora executa `lua/score_probe.lua` v3.1. Comandos novos em `score_probe_commands_v31.txt`, escritos um por linha **durante o jogo**: `START:teste01`, `MARK:GAMEPLAY`, `MARK:TRANSITION`, `MARK:RECORD`, `RESULT:teste01:183:268`. Substitua as pontuacoes por valores reais exibidos. `EXPORT` compara todas as tentativas finalizadas na sessao; `ABORT` descarta a tentativa corrente. Uma tentativa por partida, IDs nao reutilizados; marcadores fora de ordem ou repetidos sao rejeitados. O valor do candidato e congelado no exato frame em que `MARK:RECORD` e recebido; `RESULT` apenas rotula os dados. Para controles completos, capture BONUS>0, TIME>0/BONUS=0 e TIME=0/BONUS=0 em partidas distintas.

Arquivos novos em `csv/`: `score_transitions_v31.csv`, `score_markers_v31.csv`, `score_temporal_summary_v31.csv`, `score_trials_v31.csv`, `score_validation_v31.csv`. Relatorios anteriores sao preservados. Classificacoes `exact_candidate`/`binary_candidate` representam compatibilidade observada, nao endereco confirmado; sem as tres categorias, `insufficient_controls`. Não controla o jogador nem confirma gol automaticamente. Para maior precisao no frame, acrescente cada comando assim que observar o evento, com o BizHawk pausado se necessario.

## SCORE_PROBE v3 — rastreamento temporal (modo SCORE_PROBE)

O `main.lua` executa `lua/score_probe.lua` (v3). A v2 permanece em `lua/score_probe_v2.lua` para recuperacao e nao e executada automaticamente. O v3 acompanha os candidatos v1 e os enderecos manuais `0x01CF3` (u8 Time), `0x01CF8` (u16le Bonus), `0x01CFA` (u16le Total) e `0x0DC06` (u16le Total), apenas lendo WRAM. Comandos em `score_probe_commands_v3.txt`, um por linha: `START:teste01` quando iniciar gameplay; `MARK:GAMEPLAY`, `MARK:TRANSITION` e `MARK:RECORD` para registrar eventos observados; `RESULT:teste01:183:268` na tela de recorde (substituir pelos valores reais); `ABORT` cancela uma tentativa. Os comandos sao consumidos a partir do fim do arquivo na inicializacao. Cada teste recebe ID unico na sessao, sem controle de jogo.

Saidas em `csv/`: `score_transitions_v3.csv` (mudancas por frame/candidato), `score_markers_v3.csv` (marcacoes visuais), `score_temporal_summary_v3.csv` (analise por candidato) e `score_trials_v3.csv` (tentativas). Ainda nao existe reconhecimento automatico de tela ou endereco validado. Repita com BONUS positivo, TIME-only e ambos zero, em partidas independentes. Mudancas fora da tela YOUR RECORD podem indicar um sinal indireto; todas as classificacoes continuam hipoteses.

## Candidatos adicionados a investigacao (WRAM, unsigned)

- `0x01CF3` (`b`, `u8`): `TIME_SCORE` — `manual_byte_candidate`.
- `0x01CF8` (`w`, `u16le`): `BONUS_SCORE` — `manual_word_candidate`.
- `0x01CFA` (`w`, `u16le`): `TOTAL_SCORE` — `manual_word_candidate`.

Todos os tres sao hipoteses, avaliadas independentemente da lista v1; o candidato anterior `0x0DC06` tambem foi preservado. Quando ja existir interpretacao equivalente proveniente da v1, a origem manual tem prioridade sem duplicar a linha. Uma word usa dois bytes consecutivos, em little-endian. Resultados da v2 anteriores nao mudam; faca uma nova captura e `EXPORT` para incluir todos.

## Candidatos WRAM de 16 bits monitorados manualmente

O SCORE_PROBE v2 inclui permanentemente tres hipoteses fornecidas pelo operador: `0x01CF8` (word sem sinal, WRAM, candidato a Bonus Score), `0x01CFA` (word sem sinal, WRAM, candidato a Total Score) e `0x0DC06` (word sem sinal, WRAM, candidato a Total Score). O algoritmo usa `u16le` e identifica a origem como `manual_word_candidate` na coluna `v1_match` de `csv/score_validation_v2.csv`. Essas hipoteses sao avaliadas mesmo que nao tenham sido incluidas nos resultados de v1; nenhuma e promovida automaticamente a endereco confirmado. Capture novos placares visuais e exporte novamente para testar as tres hipoteses.

## SCORE_PROBE v2 — validacao cruzada (ativo)

Selecione `SCORE_PROBE` em `challenge_mode.txt`; `main.lua` executa `lua/score_probe.lua`. Usa os candidatos de `csv/score_candidates_v1.csv` (nao remove nem altera o arquivo). Em tres ou mais partidas independentes, na tela YOUR RECORD, anote o Time Score e Bonus Score efetivamente exibidos e envie uma linha por captura no arquivo raiz `score_probe_commands_v2.txt`: `CAPTURE:tentativa01:183:268`, `CAPTURE:tentativa02:213:0`, `CAPTURE:tentativa03:0:0` (exemplos, substitua pelos valores reais). Capture ao menos um caso BONUS>0, um TIME>0/BONUS=0 e um ZERO/ZERO. Use `Add-Content .\\score_probe_commands_v2.txt "CAPTURE:tentativa01:183:268" -Encoding ASCII`. Ao fim acrescente `EXPORT`.

Saidas: `csv/score_captures_v2.csv` e `csv/score_validation_v2.csv`. Comparacao byte, BCD e u16 sobre candidatos v1; `exact_candidate` significa igualdade com todos os placares anotados, `binary_candidate` apenas distingue positivo/zero, `rejected_by_controls` falha nos controles, `insufficient_controls` indica que faltam categorias. Todos permanecem HIPOTESES: reproduza em outra sessao e controle telas nao relacionadas antes de promover endereco canonico. Os dados sao de leitura apenas, nenhuma classificacao e integrada ao bot controlador.

## DRIBBLE — runtime canonico

O ponto de entrada unico do BizHawk e `main.lua`, que seleciona `MONITOR`, `DRIBBLE` ou `SCORE_PROBE` usando `challenge_mode.txt`. O modo DRIBBLE executa exclusivamente `lua/dribble_bot.lua`, consolidado a partir do ultimo runner v0.3.5. As versoes historicas `dribble_bot_v*.lua` foram retiradas da arvore ativa; continuam recuperaveis no historico Git. Os modulos reutilizaveis em `lua/challenge/` permanecem separados e versionados quando pertinente. Nao execute mais de um controlador no BizHawk. Os relatórios CSV vao para `csv/` e os arquivos de comando continuam na raiz.

O numero de versao do comportamento do bot segue v0.3.5; a mudanca e estrutural, sem alteracao intencional na politica de jogo. Testes sintéticos nao substituem testes reais no BizHawk. Revisar documentos `docs/DRIBBLE_BOT_V*.md` como registros historicos, nao como instrucoes atuais de carregamento.

## SCORE_PROBE v1 — descoberta observacional do placar DRIBBLE LV.1

Experimento de leitura de WRAM, sem controlar o jogador e sem declarar enderecos validados. Configure `challenge_mode.txt` como `SCORE_PROBE` e inicie `main.lua`. O arquivo `score_probe_commands_v1.txt` fica na raiz; os candidatos sao gravados em `csv/score_candidates_v1.csv`.

Na tela YOUR RECORD de cada caso, acrescente uma linha via PowerShell (`Add-Content .\\score_probe_commands_v1.txt "BOTH" -Encoding ASCII`, substituindo por `TIME_ONLY` e `ZERO` quando apropriado). Valores de referencia dos exemplos visuais: BOTH 183/268, TIME_ONLY 213/0, ZERO 0/0. A captura nao depende da ordem. Ao concluir as tres capturas, acrescente `EXPORT`; o algoritmo procura valores exatos e padroes positivos/zero, incluindo bytes BCD e words, e marca tudo como `hypothesis_only`. Nao execute SCORE_PROBE e o bot controlador simultaneamente. Se o jogo retornar ao menu ou mudar de tela antes do comando, refaca a sessao.

Os exemplos sao do placar final e podem variar em novas tentativas. Para testar valores diferentes, atualize as referencias do experimento antes de interpretar correspondencias exatas. A correlacao de tres capturas so gera candidatos: validar requer novas execucoes com pontuacoes diferentes e controles negativos.

## Saidas CSV (modos ativos)

Os modos MONITOR e DRIBBLE v0.3.5 gravam CSVs em `csv/`. Arquivos `.txt` de comandos continuam na raiz. Relatorios antigos na raiz nao sao movidos automaticamente; scripts Lua historicos independentes mantem seus comportamentos.

Exemplo: `Import-Csv .\csv\dribble_bot_summary_v035.csv`.

## Inicialização centralizada em main.lua

Carregue **somente `main.lua`** no Lua Console do BizHawk para iniciar o modo desejado. A seleção acontece na inicialização, lendo o arquivo `challenge_mode.txt` na raiz do repositório:

- Sem arquivo, ou com `MONITOR`: inicia o reconhecedor contextual original (modo padrão).
- Com `DRIBBLE`: inicia o bot canônico `lua/dribble_bot.lua`, com o mesmo diretório raiz e caminho de módulos definidos em `main.lua`.

No PowerShell, a partir da raiz do repositório:

```powershell
Set-Content .\challenge_mode.txt 'DRIBBLE'
```

Reinicie `main.lua` no BizHawk, depois envie `ARM` em `dribble_bot_commands_v035.txt`. Para voltar ao monitor:

```powershell
Set-Content .\challenge_mode.txt 'MONITOR'
```

Reinicie `main.lua` novamente: a escolha de modo **não muda durante uma execução**. Arquivos com valores desconhecidos geram erro explícito, em vez de iniciar um bot inesperado. A carga direta do bot antigo continua suportada apenas por compatibilidade. Os novos CSVs dos modos ativos ficam em `csv/`; os arquivos existentes nao sao movidos automaticamente. A prova de não-regressão do bot continua exigindo teste no BizHawk (5 bandeiras e rota de referência de 667 frames).

# ISSD.challenge_mode

Projeto reiniciado do zero em 21/10/2026. **v0.4 experimental**, BizHawk + Lua, International Superstar Soccer Deluxe (SNES).

Fonte canônica dos endereços e da avaliação das evidências: [ISSD.mapping/docs/CHALLENGE_MODE.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/CHALLENGE_MODE.md). Os cinco bytes são **hipóteses**, não mapeamento validado. Ver [docs/MAPPING_INTEGRATION.md](docs/MAPPING_INTEGRATION.md).

Carregue `main.lua` (único arquivo Lua executável mantido na raiz do repositório) no console Lua do BizHawk. Os CSVs e eventos são gravados na raiz do projeto. O monitor grava `challenge_transitions_v03.csv`, com frames, alterações brutas e duração dos estados. Registre mudanças de tela pelo PowerShell em `operator_events_v03.txt`, conforme [docs/MONITOR_V03.md](docs/MONITOR_V03.md).

Com Lua instalado, rode `lua tests/test_probe.lua` e `lua tests/test_monitor.lua`. Esses testes são sintéticos, não equivalem a testes na ROM.

**Não existe flag de presença do menu validada**. O monitor nunca envia inputs ao jogo, e `candidate` não significa reconhecimento confirmado.

## Reconhecedor contextual v0.4

A camada observacional v0.3 foi preservada. A v0.4 grava tambem `challenge_context_v04.csv`, requer anotacoes visuais do operador e **nunca** publica `confirmed`. Consulte [docs/CONTEXT_V04.md](docs/CONTEXT_V04.md). Teste sintetico: `lua tests/test_context.lua`.

## WRAM Cursor Discovery v1

Execute `lua/cursor_discovery.lua` **em vez de** `main.lua` para investigar o cursor de Challenge Start Menu. Capture as quatro posicoes A-B-C-A usando `cursor_capture_events_v1.txt`; os candidatos serao registrados em `cursor_candidates_v1.csv`. Leia [docs/CURSOR_DISCOVERY_V1.md](docs/CURSOR_DISCOVERY_V1.md). Os resultados sao apenas hipoteses.

## WRAM Cursor Validation v2

Execute `lua/cursor_validation.lua` sozinho no BizHawk para testar o candidato `0x01542` com sequencia A-C-B-A e controles negativos. Instrucao: [docs/CURSOR_VALIDATION_V2.md](docs/CURSOR_VALIDATION_V2.md). Nao promove evidencias automaticamente.

## Challenge Gameplay Probe v1

Execute `lua/gameplay_probe.lua` sozinho no BizHawk. Capture WRAM gameplay flags and signed world X/Y for ball and 22 players every 30 frames, with operator phase labels from `gameplay_events_v1.txt`. Output: `challenge_gameplay_v1.csv`. Protocol: [docs/GAMEPLAY_PROBE_V1.md](docs/GAMEPLAY_PROBE_V1.md). All readings are exploratory in Challenge Mode; no automatic playing flag is confirmed.

## Challenge Controlled Player Probe v1

Run `lua/controlled_player_probe.lua` alone in BizHawk to investigate `0x1ACC` and the single visible player of DRIBBLE LV.1. Annotate phases in `controlled_player_events_v1.txt`; review `controlled_player_v1.csv`. See [docs/CONTROLLED_PLAYER_PROBE_V1.md](docs/CONTROLLED_PLAYER_PROBE_V1.md). Read-only; no gameplay status confirmed.

## DRIBBLE LV.1 Focused Probe v1

Run `lua/dribble_focused_probe.lua` alone in BizHawk before selecting CHALLENGE START. Reads ball, My Team No.11, gameplay fields, stadium and geometry every 5 emulated frames; no PowerShell interaction needed during the 30-second challenge. Output: `dribble_lv1_focused_v1.csv`. See [docs/DRIBBLE_FOCUSED_PROBE_V1.md](docs/DRIBBLE_FOCUSED_PROBE_V1.md). Observational only.

## DRIBBLE LV.1 State Validation v1

Run `lua/dribble_state_validation.lua` alone in BizHawk. Observe `0x00BA`, `0x1ACC`, geometry and position changes every five frames; manually label SUCCESS, FAILURE and RETURN_MENU in `dribble_state_events_v1.txt`. Data in `dribble_state_validation_v1.csv`; see [docs/DRIBBLE_STATE_VALIDATION_V1.md](docs/DRIBBLE_STATE_VALIDATION_V1.md). No automatic outcome confirmation.

## DRIBBLE LV.1 Bot v0.1 — experimental

Run `lua/dribble_bot.lua` alone in BizHawk. Starts DISARMED; send `ARM` only once the DRIBBLE LV.1 player is visibly on the field using `dribble_bot_commands_v01.txt`. Inspect `dribble_bot_trace_v01.csv`. The initial policy assumes X increasing toward the goal and has **not** been validated as a winning strategy. Details: [docs/DRIBBLE_BOT_V01.md](docs/DRIBBLE_BOT_V01.md).

## DRIBBLE Flag Discovery v1

Run `lua/flag_discovery.lua` alone in BizHawk. Send `ARM` via `flag_discovery_events_v1.txt` once DRIBBLE LV.1 starts; it captures full WRAM periodically and ranks step-like byte candidates, writing `flag_candidates_v1.csv` and `flag_timeline_v1.csv`. This does not yet identify flag coordinates or prove collected count. See [docs/FLAG_DISCOVERY_V1.md](docs/FLAG_DISCOVERY_V1.md).

## DRIBBLE Flag Discovery v2

Run `lua/flag_discovery_v2.lua` alone in BizHawk; ARM using `flag_discovery_events_v2.txt` when gameplay starts. Samples the full WRAM every 60 frames only when GS=0 and PTR=0x0F00; exports candidate counters and bitmasks with transition frames to `flag_candidates_v2.csv` and telemetry to `flag_timeline_v2.csv`. See [docs/FLAG_DISCOVERY_V2.md](docs/FLAG_DISCOVERY_V2.md). Experimental, not a confirmed flag detector.

## DRIBBLE Flag Counter Validation v1

Run `lua/flag_counter_validation.lua` alone in BizHawk to log `0x006B4`, `0x00F2B` and `0x00EE9` **every emulated frame**, including resets in menus. Optional manual labels via `flag_counter_events_v1.txt`; results in `flag_counter_validation_v1.csv`. See [docs/FLAG_COUNTER_VALIDATION_V1.md](docs/FLAG_COUNTER_VALIDATION_V1.md). Candidate addresses, not confirmed mappings.

## DRIBBLE Flag Position Discovery v1

Load `lua/flag_position_discovery.lua` alone in BizHawk. It reads the experimentally supported `0x006B4` remaining-flags counter each frame and records player/ball world coordinates at every decrement in `flag_positions_v1.csv`; no `ARM` or automatic input. These are *collection encounter positions*, not confirmed object coordinates. [Protocol](docs/FLAG_POSITION_DISCOVERY_V1.md).

## DRIBBLE Bot v0.2 — Waypoint Navigation

Run `lua/dribble_bot_v02.lua` alone in BizHawk. Arm only once gameplay is visible by appending `ARM` to `dribble_bot_commands_v02.txt` (stop with `STOP`). Navigates five experimentally observed encounter points and advances only when the `0x006B4` count decreases. Generates `dribble_bot_trace_v02.csv`; automatic safeguards on state transitions, stalls and invalid counters. See [docs/DRIBBLE_BOT_V02.md](docs/DRIBBLE_BOT_V02.md). Experimental: automatic success is not yet validated.

## DRIBBLE Bot v0.2.1 — Precision Approach

Load `lua/dribble_bot_v021.lua` alone in BizHawk. ARM via `dribble_bot_commands_v021.txt` once in DRIBBLE LV.1. Near waypoints it uses short direction pulses and bounded local search; collection progression still requires `0x006B4` decrement. Trace: `dribble_bot_trace_v021.csv`. See [docs/DRIBBLE_BOT_V021.md](docs/DRIBBLE_BOT_V021.md). Experimental; BizHawk test pending.

## DRIBBLE Bot v0.2.2 — Waypoint Transition Fix

Use `lua/dribble_bot_v022.lua` alone in BizHawk, arm with `dribble_bot_commands_v022.txt`, and inspect `dribble_bot_trace_v022.csv`. A detected flag decrement resets the movement watchdog, gives a 60-frame grace period and emits an explicit `flag_collected` event. [Protocol](docs/DRIBBLE_BOT_V022.md). Experimental; playtest pending.

## DRIBBLE Timer Discovery v1

Run `lua/dribble_timer_discovery.lua` alone in BizHawk, append `ARM` to `dribble_timer_events_v1.txt` after challenge start and collect all five flags. It samples WRAM at 30-frame intervals, correlates changes with the fifth collection and exports `dribble_timer_candidates_v1.csv` and `dribble_timer_timeline_v1.csv`. Addresses remain **unvalidated**. [Protocol](docs/DRIBBLE_TIMER_DISCOVERY_V1.md).

## DRIBBLE Timer Discovery v2 — Phase-Aware Ranking

Load `lua/dribble_timer_discovery_v2.lua` alone in BizHawk; append `ARM` to `dribble_timer_events_v2.txt`. This read-only probe ranks TIME and BONUS candidates separately, excluding GS=6/post-game samples, and auto-finalizes after the bonus phase or gameplay exit. Outputs `dribble_time_candidates_v2.csv`, `dribble_bonus_candidates_v2.csv` and `dribble_timer_timeline_v2.csv`. [Protocol](docs/DRIBBLE_TIMER_DISCOVERY_V2.md). No clock addresses validated yet.

## DRIBBLE Timer Validation v1

Run the read-only `lua/dribble_timer_validation_v1.lua` to record per-frame u8/u16/u32 interpretations of WRAM `0x014F0..0x014F7` across TIME, fifth-flag and BONUS phases. Send `ARM`/`STOP` using `dribble_timer_validation_events_v1.txt`; output is `dribble_timer_validation_v1.csv`. [Protocol](docs/DRIBBLE_TIMER_VALIDATION_V1.md). Clock address hypotheses remain unvalidated.

## DRIBBLE Timer Decoder v1

Run `lua lua/decode_dribble_timers_v1.lua` on `dribble_timer_validation_v1.csv` to interpret experimental `0x014F0` (TIME) and `0x014F4` (BONUS TIME) seconds as packed BCD, and export the raw fractional u16 registers without presuming a scale. Produces `dribble_timer_decoded_v1.csv` and `dribble_timer_decoder_summary_v1.csv`. [Protocol](docs/DRIBBLE_TIMER_DECODER_V1.md). These addresses are not canonical until checked against HUD frames.

## DRIBBLE Bot v0.3 — Goal Completion (experimental)

Run `lua/dribble_bot_v03.lua` alone in BizHawk, using `dribble_bot_commands_v03.txt` for ARM/STOP. Preserves v0.2.2 five-flag policy and transitions to an experimental goal approach and B charge/release instead of stopping at five flags. Logs `dribble_bot_trace_v03.csv` with phases and frames. **Goal target / shooting behavior uncalibrated; gameplay exit is NOT verified success.** [Protocol](docs/DRIBBLE_BOT_V03.md).

## DRIBBLE Bot v0.3.1 — Goal & Score Validation

Use `lua/dribble_bot_v031.lua` in BizHawk, `ARM`/`STOP` via `dribble_bot_commands_v031.txt`. The v0.3 control logic is preserved; trace includes timer BCD candidates and deduplicated events. An attempt summary is written once into `dribble_bot_summary_v031.csv`. Use `CONFIRM_GOAL` and optionally `SCORE:<number>` **only after visually verifying that same attempt**. Otherwise the outcome stays `unverified`. See [docs/DRIBBLE_BOT_V031.md](docs/DRIBBLE_BOT_V031.md).

## DRIBBLE Bot v0.3.2 — Persistent Score Validation

Run `lua/dribble_bot_v032.lua` with `ARM`/`STOP` via `dribble_bot_commands_v032.txt`. Unique attempt session IDs are logged in `dribble_bot_summary_v032.csv`. After the summary is written, confirm a visually verified goal/score with `python python/confirm_dribble_score_v032.py --session <exact_session> --confirm-goal --score <score>` even if BizHawk is closed. Updates are session-targeted, idempotent and audited in `dribble_bot_score_audit_v032.csv`; all unconfirmed game exits remain `unverified`. [Protocol](docs/DRIBBLE_BOT_V032.md).

## DRIBBLE Bot v0.3.2.1 — Stuck Recovery Fix

Run `lua/dribble_bot_v0321.lua` alone in BizHawk; send `ARM`/`STOP` to `dribble_bot_commands_v0321.txt`. This version preserves flag waypoints and goal control, adds at most two 24-frame directional recovery probes for flag-phase stalls, and records recovery events to `dribble_bot_trace_v0321.csv`. See [docs/DRIBBLE_BOT_V0321.md](docs/DRIBBLE_BOT_V0321.md). Goal and score confirmation remains operator-driven via `python/confirm_dribble_score_v032.py --summary dribble_bot_summary_v0321.csv`.

## DRIBBLE Bot v0.3.2.2 — Recovery Diagnostics & Optimization

Run `lua/dribble_bot_v0322.lua` in BizHawk, arm via `dribble_bot_commands_v0322.txt`. Adaptive bounded recovery uses at most two 12-frame probes with per-frame diagnostics in `dribble_bot_trace_v0322.csv`, preserving the existing five waypoints and goal policy. [Protocol and score confirmation](docs/DRIBBLE_BOT_V0322.md). Experimental until ROM validation.

## DRIBBLE Bot v0.3.2.3 — Delayed Movement Detection

Run `lua/dribble_bot_v0323.lua` in BizHawk. After failed escape probes, the bot observes player and ball movements separately for up to 18 frames before retrying or stopping. Trace has a corrected 20-column header and records delayed-response diagnostics. See [docs/DRIBBLE_BOT_V0323.md](docs/DRIBBLE_BOT_V0323.md). Confirmation remains operator-driven.

## DRIBBLE Bot v0.3.2.4 — Initial Movement Calibration

Use `lua/dribble_bot_v0324.lua` alone in BizHawk with `dribble_bot_commands_v0324.txt` ARM/STOP. A passive 90-frame startup calibration logs first player/ball movement and possession changes in `dribble_initial_calibration_v0324.csv`; this postpones premature initial stuck detection without changing waypoint or goal inputs. [Protocol](docs/DRIBBLE_BOT_V0324.md). Not yet validated in the emulator.

## DRIBBLE Bot v0.3.2.5 — Start Synchronization

Load `lua/dribble_bot_v0325.lua` alone in BizHawk; ARM/STOP through `dribble_bot_commands_v0325.txt`. Logs first player and ball motion versus ARM and first observed BCD TIME transition to `dribble_start_sync_v0325.csv`. This measures start latency without assuming BCD-second transitions are exact clock-start evidence; steering and shooting are unchanged. See [docs/DRIBBLE_BOT_V0325.md](docs/DRIBBLE_BOT_V0325.md).

## DRIBBLE Bot v0.3.2.6 — Flag Timing & Start-State Validation

Run `lua/dribble_bot_v0326.lua` alone in BizHawk and ARM via `dribble_bot_commands_v0326.txt`. Every observed single decrement of the remaining-flags counter is recorded separately in `dribble_flag_timing_v0326.csv`, bypassing deduplication of the old event name. The ARM snapshot is recorded in `dribble_start_state_v0326.csv`. Movement, timer synchronization, and shot policies remain unchanged. [Protocol](docs/DRIBBLE_BOT_V0326.md).

## DRIBBLE Bot v0.3.2.7 — Active Start Detection

Start `lua/dribble_bot_v0327.lua` in BizHawk and ARM via `dribble_bot_commands_v0327.txt`. The independent passive detector records TIME fraction/seconds changes, first ball/player movement, and an active-start **candidate**, continuing beyond 90 frames if needed. See `dribble_active_start_v0327.csv` and `dribble_active_flag_timing_v0327.csv`. The controller is unchanged; this is not a validated game-start flag. [Protocol](docs/DRIBBLE_BOT_V0327.md).

## DRIBBLE Bot v0.3.2.8 — Deterministic Route Benchmark

Run `lua/dribble_bot_v0328.lua` alone in BizHawk. Records five per-flag segment durations and positions in `dribble_route_segments_v0328.csv` and session comparability in `dribble_route_benchmark_v0328.csv`. The reference is the observed v0327 vector 176/244/204/172/192; **no gameplay commands are changed**. See [protocol](docs/DRIBBLE_BOT_V0328.md).

## DRIBBLE Goal Counter Validation v2

Passive BizHawk observer `lua/goal_counter_validation_v2.lua` tests the experimental goal count at `WRAM 0x0DA2` with explicit START/STOP sessions, visual operator markers and negative controls. **Correlation is not yet an automatic goal confirmation**. See [protocol](docs/GOAL_COUNTER_VALIDATION_V2.md).

## DRIBBLE Goal Counter Validation v3 — Negative Controls & Goal Evidence

Passive observer `lua/goal_counter_validation_v3.lua` tracks WRAM `0x0DA2` u16 with per-session START/STOP baselines, explicit negative controls, byte consistency, resets, and correlated positive evidence. This **does not automatically verify goals or scores**. See [validation protocol](docs/GOAL_COUNTER_VALIDATION_V3.md).

## DRIBBLE Goal Evidence v4 — Context-Aware Confirmation

Passive script `lua/goal_evidence_v4.lua` correlates 0x0DA2 increments with a complete five-flag sequence, operator shot marker and GS=5, distinguishing out-of-context increments and negative controls. It does **not** automatically confirm goals or scores. See [protocol](docs/DRIBBLE_GOAL_EVIDENCE_V4.md).

## DRIBBLE Bot v0.3.3 — Integrated Goal Evidence

The single gameplay runner `lua/dribble_bot_v033.lua` samples experimental goal counter `0x0DA2` and combines increment evidence with the fifth flag and its own shot event. Inspect `dribble_goal_evidence_v033.csv` and `dribble_goal_events_v033.csv`. Route and shot commands remain unchanged and point scores are **never automatically confirmed**. [Protocol](docs/DRIBBLE_BOT_V033.md).

## DRIBBLE Bot v0.3.4 — Goal Evidence & Performance Benchmark

Run `lua/dribble_bot_v034.lua` for contextual goal counter evidence, integrated `dribble_summary_integrated_v034.csv` and per-phase timings in `dribble_performance_v034.csv`. Control strategy is unchanged; scores still require independent operator verification. [Usage and metrics](docs/DRIBBLE_BOT_V034.md).

## DRIBBLE Bot v0.3.5 — Route Optimization Benchmark

`lua/dribble_bot.lua` introduces reversible, isolated four-unit waypoint experiments (default `CONTROL`) with `dribble_route_optimization_v035.csv` and `dribble_route_experiments_v035.csv`. The goal and shot logic remain unchanged; no route improvement is asserted without emulator evidence. [Protocol](docs/DRIBBLE_BOT_V035.md).

## Organizacao dos scripts Lua

`main.lua` continua na raiz e e o ponto de entrada do monitor de Challenge Mode. Os antigos scripts Lua da raiz foram movidos para `lua/`, preservando seus nomes e conteudo. Os modulos do jogo permanecem em `lua/challenge/` e os testes em `tests/`. Para executar o bot de drible pelo Lua Console use `lua/dribble_bot.lua`; execute outros probes diretamente de `lua/`. O diretorio de trabalho do BizHawk deve continuar na raiz do repositorio, onde comandos e CSVs sao lidos/gerados.

## Modularizacao incremental do DRIBBLE v0.3.5

O arquivo `lua/dribble_bot.lua` continua sendo o ponto de entrada para o bot de drible. Infraestrutura reutilizável foi extraída sem alterar as regras de controle:

- `lua/challenge/dribble_csv_v035.lua`: inicializacao de cabeçalhos, backups seguros e escrita de linhas, preservando os mesmos formatos CSV.
- `lua/challenge/dribble_commands_v035.lua`: leitura incremental do arquivo `dribble_bot_commands_v035.txt`, ignorando linhas antigas no inicio e aguardando novas linhas completas.
- `lua/challenge/dribble_waypoints_v022.lua`, `dribble_route_optimization_v035.lua` e demais controladores mantêm os perfis existentes, incluindo `FLAG2_760_330_FLAG5_1460_360`, `CONTINUOUS_PRECISION` e `TRAVEL:AXIS`.

Teste sintético dos módulos de infraestrutura: `lua tests/test_dribble_io_v035.lua`. Teste sintético do movimento: `lua tests/test_dribble_approach_v035.lua`. Ambos exigem interpretador Lua instalado e não substituem a regressão no BizHawk. A organização mantém sondas históricas em `lua/` para rastreabilidade, em vez de excluí-las ou incorporá-las prematuramente ao runner.

## Scripts Python

Os scripts Python auxiliares ficam em `python/`; execute-os a partir da raiz do projeto para manter os caminhos padrão dos CSVs. Por exemplo: `python python/confirm_dribble_score_v032.py --help`. Os arquivos de relatório continuam na raiz; `main.lua` não foi movido.
