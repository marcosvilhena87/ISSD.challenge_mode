# PASS LV.1 v0.8.93 — passe rápido e jogador bloqueador como apoio

Base: v0.8.92. Mantém a validação da posse pelo jogador emissor, coordenadas WRAM, deslocamento diagonal e limite espacial.

## Janela livre
Depois de terminar o reposicionamento, se o corredor estiver livre, a fase `face` passa a `fast_pass`. Na verificação seguinte, confirma portador, posição e bloqueio antes de aplicar direção cardinal dominante + B simultaneamente, por até 2 frames. O evento `relay_fast_directional_b` informa direção e distância. O sinal continua experimental e não confirma recepção.

## Passe de apoio ao bloqueador
Se o corredor do passe principal estiver obstruído, o bloqueador pode se tornar o destinatário de um **passe de apoio**, mesmo que `spatial.visited[blocker]` já seja verdadeiro. Restrições: IDs 2–11, origem diferente, distância entre 28 e 410 WRAM, linha até o bloqueador livre e no máximo duas tentativas por par (origem,bloqueador). O evento `relay_support_blocker_selected` grava o receptor de apoio, alvo original, visita prévia, direção e número de tentativa. O passe de apoio é registrado como evento independente e não atribui uma nova visita automaticamente. Quando o passe de apoio não for viável, `relay_support_unavailable` explica o motivo geral.

## Validação necessária
Executar no BizHawk para observar se o B realmente gera passe após uma janela livre e se a troca de posse para o bloqueador de apoio é detectada; confirmar também se não há laços de apoio repetitivos.
