# Challenge Controlled Player Probe v1

Standalone BizHawk Lua, somente leitura, para identificar o jogador controlado em DRIBBLE LV.1. Fonte canônica: [ISSD.mapping/docs/RAM_MAP.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/RAM_MAP.md).

## Execução
Encerre outros scripts Lua e abra `controlled_player_probe.lua` no Lua Console do BizHawk. Ele gera imediatamente `controlled_player_v1.csv` e acompanha `controlled_player_events_v1.txt` na raiz do projeto. Eventos já existentes são ignorados quando o script inicia. O monitor grava amostras a cada **15 frames** e uma amostra imediata a cada evento.

No PowerShell, na raiz do repositório, marque as telas e ações **somente quando realmente visíveis**:

```powershell
Add-Content .\controlled_player_events_v1.txt 'START_MENU'
Add-Content .\controlled_player_events_v1.txt 'PLAYING_IDLE'
Add-Content .\controlled_player_events_v1.txt 'MOVE_LEFT'
Add-Content .\controlled_player_events_v1.txt 'MOVE_RIGHT'
Add-Content .\controlled_player_events_v1.txt 'MOVE_UP'
Add-Content .\controlled_player_events_v1.txt 'MOVE_DOWN'
Add-Content .\controlled_player_events_v1.txt 'DRIBBLING'
Add-Content .\controlled_player_events_v1.txt 'PAUSE'
Add-Content .\controlled_player_events_v1.txt 'RETURN_MENU'
```

Para os quatro testes direcionais, movimente o personagem **por vários frames durante a fase marcada**, de preferência em direções isoladas. O operador define a fase, não o programa. Não pressupor que dx positivo seja visualmente direita antes de calibrar orientação.

```powershell
Import-Csv .\controlled_player_v1.csv |
  Where-Object { $_.kind -eq 'operator' -or $_.controlled_changed -eq '1' } |
  Select-Object -Last 40 frame,phase,my_ptr_hex,my_slot,my_ptr_valid,controlled_x,controlled_y,controlled_dx,controlled_dy,controlled_changed,ball_x,ball_y,player_possession,possession_matches_my,gameplay_active,error_count |
  Format-Table -AutoSize
```

## Leituras
- `0x1ACC`, `0x1AFC`: u16 little-endian, ponteiros/bases candidatos. Só desreferenciar bases alinhadas `0x0500..0x0F00` ou `0x1000..0x1A00` com passo `0x100`, respectivamente.
- Base MY válida: coordenadas s16 em `base+0x2A`, `base+0x2C`. CPU equivalente, apenas se ponteiro válido.
- `0x00A6` Player Ball Possession (u16); `0x104C` Team Ball Possession em **u8 e u16**, para investigar diferença WCH/catalogo; `0x00BA` Game State (u16); `0x096E` My Side (u8); `0x106E` CPU Side (u8); `0x0006` Gameplay Active (u8); Ball X/Y (s16 em `0x042A/0x042C`).
- `controlled_dx/dy` representam diferença desde **amostra anterior somente se a mesma base válida persistir**. Caso contrário são vazios, para evitar falsa velocidade após mudança de ponteiro. `controlled_changed` e `ball_changed` não validam atividade automaticamente.
- Registros com coordenadas, ponteiro válido na faixa ou posse igual ao ponteiro não provam existência ou visibilidade da entidade em Challenge Mode. Testar controle negativo nos menus, pausar e reiniciar. Não gravar ROMs ou dumps.

Teste sintético: `lua tests/test_controlled_player_probe.lua`.
