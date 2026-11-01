# PASS LV.1 v0.8.39 — aproximação guiada pelas coordenadas dos jogadores

A coordenada (0,0) corresponde ao canto superior esquerdo: **RIGHT aumenta X; DOWN aumenta Y**. O módulo Feet mede `dx=alvo.x-portador.x` e `dy=alvo.y-portador.y`. A versão 0.8.39 usa esses sinais antes de preferir direcionais especiais.

- **5→8:** se `dx>20` e RIGHT não estiver suspenso, prioriza RIGHT. O teste passa a sustentar RIGHT por **até oito frames consecutivos** antes da pausa neutra. Registra X/Y do 5 e 8 a cada frame de aproximação e o deslocamento residual nos quatro frames neutros iniciais. A cada frame mantém a revalidação de posse, bola perto dos pés e geometria. Regressão forte, regressão acumulada ou parada recorrente seguem causando interrupção segura (v0.8.38).
- **8→9:** a diagonal UP+RIGHT só é selecionada caso `dx>10` e `dy< -10`, isto é, 9 esteja efetivamente à direita e acima de 8. Do contrário, a busca cardinal calibrada decide entre os direcionais.
- **Demais pares:** mantêm seleção por custo geométrico e feedback; `approach_coordinate_decision` registra dx/dy, direção e duração de cada rajada.
- Mantidas rota 6→3→2→4→5→8→9→7→10→11, bloqueio RIGHT preparatório 6→3, dois Down antes de Down+B 4→5 e monitor pós-X.

A sonda de oito frames altera o experimento e exige validação real no BizHawk. Nenhuma vitória oficial pode ser inferida só das transferências candidatas.
