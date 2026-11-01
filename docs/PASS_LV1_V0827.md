# PASS LV.1 v0.8.27 — extensão segura de aproximação

Base: v0.8.26. A tentativa anterior chegou a 9/10 e a aproximação 7→10 reduziu a distância de 513,89 para 367,41 unidades, mas encerrou aos 90 frames direcionais antes de atingir alcance seguro.

A v0.8.27 mantém um limite inicial de 90 frames, porém pode ampliá-lo em blocos de 30 frames até um máximo absoluto de 210. Cada extensão exige métricas atuais válidas, progresso líquido de pelo menos 12 unidades desde o início, ausência de estagnação no último monitoramento e distância atual não mais que 12 unidades acima da melhor distância registrada. Sem tais condições, interrompe em approach_timeout.

Durante a extensão, os movimentos continuam em rajadas de até 4 frames direcionais com pausa neutra para observar progresso. As verificações de bola próxima do portador, geometria (distância e desvio lateral), estabilização de posse e alinhamento A–bola–B permanecem ativas. A expansão de limites geométricos continua limitada a nível 4. Não há B durante a aproximação.

Auditar csv/pass_auto_v06.csv: approach_extended (limite antigo/novo, distância atual, melhor distância), approach_progress e approach_timeout. O monitor de gols da v0.8.26 permanece em csv/pass_goal_evidence_v0826.csv; se completar 10/10, observar 300 frames após X.

Este ajuste ainda não foi testado no BizHawk; seus benefícios não estão confirmados.
