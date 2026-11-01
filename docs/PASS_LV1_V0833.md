# PASS LV.1 v0.8.33 — sonda medida e preparação de passes

Base: v0.8.32. Mantém a rota padrão **6→3→2→4→5→8→9→7→10→11**.

- **6→3:** não seleciona RIGHT na aproximação, e suprime RIGHT sem B durante a preparação desse par. A direção no próprio frame do passe (com B) permanece calculada pelo controlador de passe: não há promessa de 3 como receptor real. Novo evento `first_pass_right_suppressed`.
- **5→8:** prioriza RIGHT nas duas primeiras rajadas, depois usa feedback e vetores aprendidos, que podem escolher outra direção se RIGHT falhar.
- **Recuperação:** quando só resta uma sonda exploratória de até quatro frames, registra `recovery_phase=awaiting_sample` e passa obrigatoriamente por amostra neutra **antes** de avaliar o timeout. Se não houver melhora de distância nem lateral, encerra com `approach_probe_failed`; havendo melhora, registra `approach_probe_result` e concede espaço para até mais 16 frames, sempre sob o teto global de 210. Vetores medidos contrários e direções já identificadas como imóveis são excluídos da escolha exploratória.

Preserva a checagem da bola, os limites geométricos, a regra Down+B de 4→5, as demais políticas adaptativas e o monitor de evidência de gol pós-X da v0.8.26. O resultado de passe e vitória no desafio ainda precisa ser comprovado no BizHawk. Testes estruturais não substituem validação de tempo de execução.
