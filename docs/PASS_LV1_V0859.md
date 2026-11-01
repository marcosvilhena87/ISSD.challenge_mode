# PASS LV.1 v0.8.59 — finalização mais próxima do gol

Base: v0.8.58; preserve integralmente a cadeia de passes e a observação de gol de 300 frames baseada no DRIBBLE.

O chute X anterior foi emitido de longe (RIGHT+DOWN+X) e não gerou incremento do contador nos 300 frames analisados. A v0.8.59 não repete automaticamente o chute distante. Ao completar 10/10 e observar o bônus, a rotina compara a coordenada horizontal da bola com a coordenada horizontal do goleiro — **proxy experimental**, não coordenada validada da linha do gol.

Se o afastamento horizontal for maior que 135 unidades WRAM, move o portador com RIGHT/LEFT, com ajuste vertical apenas se |dy|>90. A posse precisa estar consistente com bola a no máximo 18 unidades dos pés do portador. A aproximação é limitada a 120 frames próprios e continua sujeita às janelas de finalização preexistentes (180 frames após o início do bônus e 240 após completar a cadeia). Se não alcançar a distância alvo, registra `shot_blocked_too_far` e NÃO envia X.

Após chegar à distância permitida, mantém a pausa e o disparo X únicos existentes, com pontaria baseada na posição do goleiro (não validada como centro do gol). Gera `csv/pass_shot_trajectory_v0859.csv` contendo amostras da bola e goleiro no chute, em todos os primeiros 60 frames após X e a cada dez frames seguintes até 300. A contagem de gols permanece separada no `pass_goal_evidence_v0826.csv`. O evento `finish_goal_approach` documenta distância inicial e melhor aproximação.

Esta é uma melhoria experimental de posicionamento; 135 WRAM não foi calibrado como distância ideal de chute e não prova que X marcará gol. Para validação real, comparar trajetória, contador de gol e sinais visuais no BizHawk.

Teste estrutural: `python -m unittest discover -s tests -p test_pass_v0859_static.py`.
