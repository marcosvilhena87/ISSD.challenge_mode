# PASS LV.1 — v0.8.95: passe de apoio no planejamento

Base: v0.8.94.

Quando o jogador final estiver protegido por um bloqueador, a fase de **planejamento** passa a avaliar se o próprio bloqueador pode receber um passe de apoio. O jogador pode já estar marcado como visitado: isso não impede a transferência. Aplicam-se as verificações de posse do emissor, intervalo de 28–410 WRAM, linha de passe sem outro bloqueador e limite de duas tentativas por par (origem, apoio).

Um passe de apoio viável dispara `final_support_planned`, armazenando `original_target` como alvo final e `support_target` como jogador intermediário; a fase de lançamento rápido então usa coordenadas do novo par. Se o portador espacial passar a ser o intermediário, `final_support_received` registra o fato e a rota ao alvo final é recalculada. Uma alternativa não viável gera `final_support_rejected`, com motivo de limite ou geometria inválida; o controlador ainda pode realizar reposicionamentos e aguardar oportunidades.

A prioridade do último não visitado, os passes rápidos, os movimentos diagonais e a telemetria da v0.8.94 permanecem. A detecção de portador/recepção continua sendo proxy espacial e precisa de validação no BizHawk.
