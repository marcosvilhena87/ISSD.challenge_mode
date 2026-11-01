# PASS LV.1 v0.8.67 — orientação direcionada em 4→5

Problema observado pelo operador: o jogador 4 executa o passe de costas para o 5, resultando em bola curta. Duas execuções anteriores produziram trajetória de aproximadamente 101–102 WRAM e caminhada do receptor de cerca de 72–74 WRAM.

## Experimento específico, sem alterar os outros pares
Anteriormente, a preparação de 4→5 pressionava sempre **Down por dois frames**, independentemente da posição do 5, soltava por um frame e ainda acionava a fase genérica de orientação por **quatro frames**. Agora:
1. Localizar a posição atual de 4 e 5, calcular a direção cardinal predominante do vetor do portador ao receptor e pressioná-la por **dois frames sem B**.
2. Soltar todos os botões por um frame para evitar movimento adicional.
3. Ir diretamente à fase de passe `hold`, que mantém as verificações de segurança e o passe direcional B já existentes.
4. Registrar `facing_45_target_step` e `facing_45_release` em `csv/pass_auto_v06.csv`; correlacionar com `pass_reach_v0864.csv` para estudar o trajeto da bola e a caminhada dos dois jogadores.

O código não lê um endereço de orientação WRAM validado; logo, as entradas do direcional são **comandos de orientação propostos**, e não confirmação de que o sprite virou. A orientação e a distância do passe devem ser validadas no BizHawk. Mantidas a rota, a antecipação 7→10, as proteções de gol do estádio e a verificação pós-X.

Teste estrutural: `python -m unittest discover -s tests -p test_pass_v0867_static.py`.
