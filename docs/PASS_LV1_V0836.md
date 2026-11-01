# PASS LV.1 v0.8.36 — RIGHT prioritário para 5 → 8 com feedback real

Base v0.8.35. A aproximação 5→8 começa dando preferência a RIGHT, mas agora a preferência depende do efeito medido na pausa neutra. Se a distância ao jogador 8 diminuir mais de 0,5 unidade, mantém RIGHT elegível. Se a distância aumentar mais de 2 unidades, ou o deslocamento observado do portador contradizer o comando RIGHT (projeção < -0,5), suspende RIGHT nesse par e acrescenta penalização. Duas rajadas sem alteração relevante também suspendem. A recuperação não volta a usar RIGHT enquanto ele estiver suspenso. O estado é reiniciado quando muda o alvo.

O novo evento `approach_right_feedback` registra resultado, variação de distância, projeção observada e bloqueio. Mantêm-se a calibração individual de movimento, limite absoluto de 210 frames, verificação de bola e geometria, rota 6→3→2→4→5→8→9→7→10→11, pré-Down e Down+B de 4→5 e experimento UP+RIGHT em 8→9 da v0.8.35.

O efeito da preferência RIGHT depende do comportamento real do jogo e ainda precisa de validação no BizHawk. Testes estruturais não comprovam sucesso do desafio.
