# DRIBBLE Timer Discovery v2 — Phase-Aware Ranking

V2 mantém a v1 intacta. Separação dos snapshots pela WRAM operacional do desafio:
- **TIME:** GS=0, PTR=0x0F00 e bandeiras restantes em 1..5.
- **BONUS:** GS=0, PTR=0x0F00 e contador de bandeiras 0.
- **EXCLUDED:** menus, GS=6, ponteiro não correspondente e limpeza de memória após partida.

Esses nomes são rótulos de análise, não endereços validados dos relógios. TIME e BONUS TIME podem se sobrepor ou ser representados em formato diferente do de bytes simples.

## Executar
1. Encerre scripts Lua antigos e `git pull --ff-only origin main`.
2. Carregue **`dribble_timer_discovery_v2.lua`** no Lua Console.
3. Comece DRIBBLE LV.1 e execute `Add-Content .\dribble_timer_events_v2.txt 'ARM'`.
4. Colete as cinco bandeiras. O script captura a WRAM de 128 KiB a cada 30 frames, até 75 snapshots, ou até oito snapshots após a quinta bandeira; também finaliza ao sair do gameplay. São apenas leituras, mas podem desacelerar a emulação.
5. Para encerrar antecipadamente: `Add-Content .\dribble_timer_events_v2.txt 'STOP'`. Não interrompa o script antes de ele produzir os rankings.
6. Envie `dribble_time_candidates_v2.csv`, `dribble_bonus_candidates_v2.csv` e `dribble_timer_timeline_v2.csv`, incluindo observações visuais dos dois cronômetros em momentos diferentes se possível.

O ranking valoriza mudanças repetidas por amostra, incrementos/decrementos unitários e estabilidade na fase oposta. Candidatos podem ser animações, posição ou dados diversos; não há reconhecimento independente do HUD. A janela BONUS pode ter menos de três snapshots: nesse caso o ranking BONUS fica vazio, o que não significa ausência de timer. Os endereços reais e seus formatos precisam de validação dirigida posterior.

Teste sintético: `lua tests/test_timer_discovery_v2.lua`.
