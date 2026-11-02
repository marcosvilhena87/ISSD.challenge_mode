# PASS LV.1 — v0.9.6: recuperação rápida do gate de posse

Base v0.9.5. Preserva o início na primeira queda do cronômetro, prazo de 30 segundos, direção do B por geometria, watchdog e finalização.

Caso observado: na rota 7→8, a geometria já havia reduzido a distância a cerca de 100 WRAM, mas o controlador convencional retornou `possession_gate_timeout` com `spatial.holder=7`. Recomeçar toda a aproximação desperdiçaria os segundos restantes.

Novo fluxo: ao retornar `possession_gate_timeout` com o relógio iniciado e ainda positivo, o controlador confere o portador espacial e o destino original (somente se origem ainda coincide com o portador), coordenadas atuais, distância ao receptor até **185 WRAM**, desvio vertical até **105 WRAM**, distância da bola ao portador até **18 WRAM** e até **duas tentativas por par**. Se tudo estiver válido, entra diretamente na fase especial `face` e tenta B com direção recalculada na saída. Registra `possession_gate_fast_recovery` com distância, direção, posse, tempo e tentativa.

Se a recuperação rápida não for segura ou viável, reinicia o controlador convencional com estado de aproximação limpo e registra `possession_gate_restarted` com detalhes dos limites. O controlador especial continua sujeito às validações internas da fase `face` e à medição da transferência; nenhum sucesso oficial é inferido a partir do comando B.

Testar em BizHawk: verificar a transição 7→8, eventos de recuperação, botões realmente enviados, recepção espacial e dez participantes antes de zero.
