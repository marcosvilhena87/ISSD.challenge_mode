# Monitor de transições v0.3

Coleta experimental no BizHawk 2.11.1 (Lua). **Nenhuma flag de menu validada**. O monitor é de leitura apenas.

## Execução
Abra a ROM no BizHawk, execute `lua/main.lua` pelo console Lua com diretório de trabalho configurado para a raiz do repositório (onde estão `lua/` e os arquivos de saída).

O arquivo `challenge_transitions_v03.csv` recebe linhas `transition` quando **qualquer um dos cinco bytes muda**, incluindo os valores inválidos 4 e 5; grava número do frame, estado candidato, bytes brutos, fase manual e a duração em frames do estado anterior. A linha inicial é um snapshot. O arquivo é acrescido entre sessões; a coluna `session` permite diferenciá-las.

## Informar a tela enquanto monitora
Num PowerShell aberto na raiz do repositório, execute, por exemplo:
```powershell
Add-Content .\operator_events_v03.txt 'menu'
Add-Content .\operator_events_v03.txt 'level_select'
Add-Content .\operator_events_v03.txt 'playing'
Add-Content .\operator_events_v03.txt 'pause'
Add-Content .\operator_events_v03.txt 'exit'
```
Valores reconhecidos: `menu`, `level_select`, `playing`, `pause`, `exit`, `main_menu`, `training`, `other`. O operador deve enviar um evento **na hora** da mudança visível. Eventos são colhidos pelo script com o frame em que são lidos, não necessariamente o frame exato da ação. A fase manual permanece até ser trocada.

O leitor ignora linhas já existentes ao iniciar. Os arquivos CSV/TXT locais devem ficar fora do Git. Não registre ROMs, savestates ou dumps brutos. Documente hash da ROM, versão do emulador, início da sessão, ações e controles negativos separadamente.

## Limites
A alteração de `0x1550` para 4/5 **não cria novos níveis**. A classificação é `unknown` fora da faixa. Nenhuma saída `candidate` permite ao bot jogar. A coleta por transição não armazena todos os frames inalterados. A duração é calculada em relação à transição anterior.
