# PASS LV.1 v0.8.52 — observação neutra e continuidade 6→7

**Base:** v0.8.51. **Rota preferencial:** 6→2→3→4→5→8→9→7→10→11.

## Janela neutra em 6→7

Quando a primeira leitura após uma rajada de movimento detecta o jogador 6 sem deslocamento em X/Y, o bot executa mais **dois frames neutros** antes de consolidar o feedback direcional. Essa espera curta dá oportunidade para observar latência/animação sem classificar uma direção como ineficaz na primeira leitura. Os limites gerais de posse, geometria e tempo permanecem vigentes. Eventos: `approach_67_delayed_motion` e `approach_67_neutral_wait`.

## Garantia lógica de continuidade após 6→2

A lista de visitados marca quem **já recebeu a bola**, não quem perdeu o direito de voltar a portar a bola. Ter realizado 6→2 ou já ter marcado 6 como visitado **não desqualifica** 6→7 quando o controle volta ao jogador 6 e o 7 ainda não recebeu. A função `Ordered.can_relay_six_seven(holder, visited)` explicita essa regra; em recuperação de receptor inesperado, o estado de aproximação anterior é reiniciado e o evento `route_67_continuity` confirma que 7 permanece elegível. Isso não força o passe diretamente se outros jogadores ainda não visitados vierem antes de 7 na rota, nem garante fisicamente a recepção: apenas evita bloqueio lógico por histórico de 6→2.

## Preservado
Rota adaptativa por receptor observado, distância mínima 24 WRAM, Control Pad+B, 5→8 RIGHT, 8→9 previsão, 7→10 prioridade RIGHT, limite absoluto 210 frames. Testes estruturais adicionados; execução real em BizHawk pendente.
