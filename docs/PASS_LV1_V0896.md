# PASS LV.1 — v0.8.96: apoio universal antes dos desvios

Base: v0.8.95.

O planejador direcional agora considera como alvo tanto o último ausente quanto o próximo ausente indicado por `Ordered.next`; assim, o mecanismo de apoio não depende de restar apenas um jogador. Quando o caminho primário estiver bloqueado, avalia **antes** de iniciar desvios 9→7 e demais reposicionamentos se o bloqueador pode receber a bola. O jogador intermediário pode já estar visitado. Ao selecionar apoio, mantém o `original_target`, grava `support_target`, define o emissor real e entra na fase de passe rápido com checagem de posse e bloqueio.

Para reduzir laços 9→6→9, impede apoio ao portador anterior, mantém limite de duas seleções por par origem–apoio e intervalo de 90 frames. Os eventos `universal_support_planned` e `universal_support_rejected` registram seleção e motivos `immediate_return`, `attempt_limit`, `invalid_geometry`, `cooldown`. O alvo original continua prioritário após a troca espacial de posse, mediante replanejamento.

Observações espaciais não confirmam por si só sucesso no desafio. Esta mudança requer validação no BizHawk.
