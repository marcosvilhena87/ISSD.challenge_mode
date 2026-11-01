# PASS LV.1 v0.8.54 — separar fuga do receptor 9 de falha do portador 8

Base v0.8.53. Modificações específicas de 8→9:
- Estimar avanço projetado do portador e fuga do receptor após cada rajada.
- Se o portador avança >0,5, o receptor se afasta mais do que ele e a distância aumenta >1,5, registrar o crescimento em `pair_89_escape_growth`, **sem somá-lo ao orçamento de regressão atribuída ao portador**.
- Manter `pair_89_total_growth` para aumentos não atribuídos a fuga do receptor e manter parada por duas falhas de avanço do portador ou crescimento desse orçamento >65.
- Permitir até **duas extensões de 30 frames** de aproximação quando houver progresso projetado do portador em duas avaliações; o limite absoluto permanece **210 frames**.
- O log `approach_89_relative_feedback` apresenta `receiver_caused`, `escape_growth` e `carrier_progress_streak`. `approach_extended` apresenta `reason=pair_89_receiver_escape_progress` quando aplicável.
- Não considerar essa extensão prova de progresso líquido; a posição real ainda decide a segurança do passe. Não altera previsão do receptor em quatro frames.

Inclui `tests/test_pass_v0854_static.py` e `tests/test_pass_v0854_67_controlled.lua`, teste controlado que instancia o módulo com geometria 6→7 e exige UP+RIGHT sem B. O teste Lua não substitui execução de controle de movimento no BizHawk.

Preservados a rota 6→2→3→4→5→8→9→7→10→11, a tolerância a receptores inesperados, o mínimo global de 24 WRAM, a rotina de 6→7 e a finalização após os 10 jogadores.

A validação real de passes, bônus e gol permanece pendente.
