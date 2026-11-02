# PASS LV.1 — v0.9.12: prioridade 6→2 e avaliação antecipada de apoios

Base v0.9.11. A versão acrescenta prioridade ao jogador 2 quando o portador é o 6, o 2 ainda não foi visitado e a geometria entre eles tem distância <=240 WRAM e diferença vertical <=125 WRAM. Isso abre oportunidade a alinhamento curto pelos controladores existentes, sem criar caminhada irrestrita ou dispensar validações de posse. Log `priority_6_to_2`.

Também acrescenta `preemptive_relay`: se o alvo está a mais de 185 WRAM, examina jogadores **já visitados** para servir de apoio antes de existir bloqueador. Só sugere apoios com duas pernas de 28–185 WRAM, alinhamento vertical <=105, sem bloqueadores e vantagem heurística >35. Registra `preemptive_relay_candidate`. A execução do apoio continua sujeita às verificações do mecanismo `universal_support_planned` da v0.9.11 (inclusive limites de tentativas, posse e cooldown).

A estratégia v0.9.9 permanece como fallback; o monitor de Time Score da v0.9.11 e o módulo de finalização v0.9.7 não foram alterados. Não garantimos que todo início por jogador 6 gere automaticamente 6→2: outros controladores podem estar ativos, e a mudança evita forçar B sem posse/alcance.

Testar no BizHawk verificando `priority_6_to_2`, `queue_alignment_started`, `preemptive_relay_candidate`, progresso 10/10, chute X e Time Score. A pontuação oficial de referência é 309, Time Score 35. Os testes adicionados são estruturais, não substituem análise sintática Lua e execução dinâmica.
