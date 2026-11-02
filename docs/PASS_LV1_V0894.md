# PASS LV.1 — v0.8.94: alvo final prioritário e recuperação

Base: v0.8.93.

Quando apenas um jogador de linha entre 2 e 11 não tem visita espacial registrada, a função `last_missing_710` determina o alvo final. A rota especial dá prioridade ao `missing` antes de qualquer devolução programada 7→10. O evento de coordenadas também usa o alvo final antes de qualquer `long_710.target` anterior.

A cada mudança no conjunto de visitados, `final_target_changed` registra o novo destino e limpa contadores de tentativas anteriores. Mudanças de posse geram `final_holder_changed`. Se o controlador está pronto, `final_stale_target_cleared` elimina um alvo antigo que não seja o final nem o alvo original de um desvio de apoio. Após uma tentativa concluída ou cancelada, `final_retry_rearmed` retoma a decisão após o cooldown, reiniciando tentativas do par, mas preservando as proteções de posse, geometria, contador de apoio e intervalos.

Os passes intermediários continuam permitidos quando o bloqueador oferece um corredor válido, independentemente de já ter sido visitado. Eventos de recepção são apenas proxies espaciais; o teste no BizHawk é obrigatório antes de declarar conclusão do desafio.
