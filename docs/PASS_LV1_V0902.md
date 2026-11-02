# PASS LV.1 v0.9.2 — recuperação após approach_timeout

Base: v0.9.1. Preserva o ajuste final dos passes por coordenadas (incluindo 2→3 DOWN+B) e a finalização da v0.9.0.

Ao ocorrer `approach_timeout` do controlador convencional, a rotina não encerra imediatamente a sessão. Verifica se o portador ainda está com a bola, se as coordenadas são válidas e se o par origem–destino tem menos de três recuperações. Entrando em `recover_approach`, lê a geometria atual a cada frame e caminha com dois eixos quando necessário, sem pressionar B ou X nessa fase.

O esforço termina após ganho mínimo de 12 WRAM, 30 frames, caminhada de 50 WRAM ou 12 frames sem melhora da distância. Registra `approach_timeout_recovery_started` e `approach_timeout_recovery_result`, com duração, caminhada medida, ganho e distância restante. Em seguida, cria `Auto.new()`, limpa os contadores/estado de aproximação antigos e retorna ao fluxo de planejamento. Sem progresso, registra `approach_timeout_recovery_fallback` e libera o controlador convencional por 48 frames. Ao esgotar tentativas ou perder a posse, registra motivo correspondente.

Esta é uma recuperação experimental; validação em BizHawk é necessária antes de afirmar que o bot retomou a circulação da bola. Visitas e recepções espaciais não são confirmação oficial do desafio.
