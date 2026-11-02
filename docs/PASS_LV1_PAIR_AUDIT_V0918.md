# PASS LV.1 — auditoria integrada v0.9.18

Base: branch experimental v0.9.17; referência de maior pontuação observada na WRAM: v0.9.16 (Time Score 122, Bonus Score 274, Total 396); sem confirmação visual da tela oficial.

## Gargalos observados em v0.9.17
- 6→2: 224 frames totais; 179 até primeiro B; 216 frames sem alteração de posição no intervalo de posse registrado.
- 9→7: 222 frames totais; 196 até B; movimento prolongado.
- 8→11: 170 frames, porém um B tinha como receptor indicado 9; divergência entre alvo planejado e portador espacial posterior.
- 5→8: 135 frames; conclusão por controlador convencional após fallback exclusivo.
- 10→11: a rota variou, 11 foi visitado antes de 10; não otimizar por sequência fixa.

## Alteração nesta branch
Telemetria observacional `pair917_target_mismatch`: registra divergência entre último receptor indicado por B e próximo portador espacial quando ambos são conhecidos, com frame de B. O campo `last_target` também é incluído em `pair917_holder_summary`. Essas divergências **não provam** erro de passe: pode haver toque intermediário, atraso de memória ou mudança de posse entre frames.

Nenhum novo impulso de controle foi introduzido. Preserva prioridades 6→2 e 5→8, monitor WRAM, temporização de fronteira e finalização X.

## Próximos passos
Capturar sessões repetidas, separar latência entre B e troca de posse, correlacionar ΔXY/bola/jogadores e medir variância do Time Score antes de tentar política adaptativa para 9→7. Verificar sintaxe Lua no ambiente local e testar no BizHawk. Referência correlata: `marcosvilhena87/ISSD.mapping/docs/PASS_LV1_EVIDENCE_V0918.md`.
