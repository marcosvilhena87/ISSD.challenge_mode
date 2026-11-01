# PASS LV.1 v0.8.32

A rota padrão foi alterada para **6→3→2→4→5→8→9→7→10→11**. A regra especial 6→2 (UP+B) permanece cadastrada mas não é mais usada como primeiro passe; a seleção pode acioná-la apenas em situações de replanejamento. O passe 4→5 segue Down+B.

Na ausência de vetor aprendido promissor, a recuperação da aproximação pode usar uma exploração direcional de **quatro frames** (uma tentativa por alvo). A direção escolhida difere da última e da última direção identificada como imóvel, respeitando a proibição especial de RIGHT em 6→2. Uma pausa neutra mede se distância ou desvio lateral melhorou; se nenhum melhorar, `approach_probe_failed` encerra o bot. A recuperação baseada em vetor permanece com teto de 16 frames e limite global de 210.

Três observações repetidas de ausência de movimento por direcional elevam sua penalidade e geram `approach_direction_still`. Os novos eventos `approach_probe_result` e `approach_probe_failed` ajudam a avaliar progresso. Mantidos os controles de posse/bola, rota adaptativa, medição dos deslocamentos de portador/receptor e detector pós-X.

Não houve execução no BizHawk; validar com savestate comum e CSVs.
