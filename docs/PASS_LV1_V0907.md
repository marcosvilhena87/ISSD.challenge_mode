# PASS LV.1 — v0.9.7: corrigir módulo de finalização em cache

Base: v0.9.6, cuja cadeia de passes registrou 10/10 antes do zero no cronômetro principal.

**Causa tratada:** o arquivo `pass_finish_v07.lua` contém `MAX_APPROACH_FRAMES=210`, mas o `main.lua` não removia `challenge.pass_finish_v07` de `package.loaded`. Quando o estado Lua do BizHawk persiste ao reiniciar scripts, `require` podia reutilizar a versão antiga com 120 frames, compatível com o bloqueio observado.

Agora o script executa `package.loaded["challenge.pass_finish_v07"]=nil` antes de `require`, exige `Finish.VERSION=="0.9.7"` e `Finish.MAX_APPROACH_FRAMES==210`, e imprime a versão carregada no boot. O limite geométrico de 135 WRAM para permitir X, a checagem de bola aos pés e a janela de bônus permanecem. A rotina não força X fora dessa faixa.

Aproximação encerrada por 210 frames ou falta de progresso agora preenche `aim_reason` com gap/frames/recovery; o controlador registra `finish_x_verified_output` no frame em que X é montado, juntamente com botão B, etapa de conclusão e bônus. Os logs de trajetória e de monitoramento passivo pós-X já existentes continuam preservados.

**Validação necessária:** reiniciar `main.lua` no BizHawk, confirmar `finish_version=0.9.7 max_approach_frames=210`, atingir 10/10, checar `finish_x_verified_output` e evidências posteriores. Nenhum evento espacial isolado comprova gol ou conclusão oficial.
