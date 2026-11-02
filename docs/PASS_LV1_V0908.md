# PASS LV.1 v0.9.8 — otimização do Time Score

Base v0.9.7, que concluiu 10/10 no prazo, emitiu X e teve incremento do contador de gols. A finalização e sua recarga não foram modificadas.

Objetivo: **priorizar passes que dispensam caminhada**. A seleção de alvo na fila especial passa a procurar todos os jogadores 2–11 ainda não visitados, usando coordenadas WRAM atuais. Um passe direto é candidato somente se a distância for 28–185 WRAM, o desvio vertical absoluto for <=105 WRAM e não houver bloqueador detectado. Dentre esses candidatos, escolhe o menor custo geométrico `distance + 0.30 * abs(dy)`. Esse é um proxy de custo, não um modelo calibrado de segundos. Sem candidato direto, mantém a fila anterior.

O watchdog e a fase `align` também preferem o alvo de passe direto quando disponível. Eventos: `time_score_pass_first` relata alvo/distância/tempo restante, e `time_score_new_visitor` registra progresso dos dez jogadores e frames desde a visita anterior. Isso facilita identificar trechos lentos.

Limitações: controladores convencionais ainda têm decisões próprias; essa mudança não é um otimizador global de sequências nem garante redução da pontuação temporal. O estado da trajetória vencedora permanece disponível na branch v0.9.7 para comparação A/B. A confirmação de sucesso oficial exige visualização do resultado no jogo. Validar no BizHawk antes de mesclar.
