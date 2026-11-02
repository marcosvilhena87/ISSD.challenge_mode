# PASS LV.1 — v0.9.4: janela de 30 segundos e watchdog ativo

Base: v0.9.3; preserva direções finais por geometria, reconciliação de posse, recuperação após timeout e finalização adaptativa.

**Orçamento da fase de passes:** utiliza o campo `time` lido do BCD WRAM pelo módulo `pass_timers_v05`, quando plausível no intervalo 0–30. Quando o contador chega a zero antes de 10/10, a cadeia encerra a tentativa e registra `pass_time_budget_expired`. Não usa 1800 frames como substituto automático: o tempo do jogo pode não coincidir com 60 fps do emulador. A interpretação desse campo ainda requer validação em execução real. A finalização após 10/10 conserva a janela de bônus independente.

**Watchdog ativo:** o estado `ready` com portador e alvo sem ação por 24 frames (12 quando tempo observado <=10) inicia `watchdog_move` se houver posse e geometria válida. Move o portador de acordo com dx/dy e para após 12 frames, 35 WRAM percorridos, 12 WRAM de ganho ou cronômetro zero. Registra `watchdog_active_move`, `watchdog_motion_result` e `watchdog_stall_detected`. Após falta de progresso, alterna movimento diagonal/vertical/horizontal nas tentativas seguintes, no máximo quatro por par. O watchdog anterior permanece como fallback. Não pressiona B ou X ao mover.

**Ponto de atenção:** a política de prazo foi implementada para a cadeia de passes; nem todos os demais timers de observação e recuperação foram recalibrados para um orçamento temporal global. Testar no BizHawk antes de declarar sucesso ou conformidade oficial do desafio. Evidência 10/10 permanece espacial.
