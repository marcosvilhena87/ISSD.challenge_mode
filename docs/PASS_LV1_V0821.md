# PASS LV.1 v0.8.21 — comparação direcional A/B

## Modos
- CALIB:A (padrão): ao usar DIRECTION:AUTO, pressiona **apenas o eixo cardinal predominante + B**. Por exemplo, alvo acima e um pouco à esquerda: Up+B.
- CALIB:B: ao usar DIRECTION:AUTO, mantém o cálculo diagonal da v0.8.20. No mesmo exemplo: Up+Left+B.

Os modos são definidos antes de ARM; não são alterados durante uma cadeia em execução. A escolha é preservada entre transferências dessa mesma cadeia. Os controles de proximidade, posse, alinhamento e ordem 6,2,3,4,5,8,9,7,10,11 permanecem.

## Evidência
- pass_auto_v06.csv: evento pass_pulse com calib=A/B, evento early_flight com dx/dy relativo à bola no primeiro frame de B, coletado até 18 frames após soltar o pulso.
- pass_inputs_v081.csv: controle por frame. O registro duplicado de approach_step foi removido do runner.
- pass_direction_v072.csv: receptor observado e resultado de transferência.

## Procedimento controlado
1. Voltar ao mesmo savestate inicial; iniciar main.lua.
2. Rodar CALIB:A, DIRECTION:AUTO, PASSBTN:B, AUTO:ON, ARM, registrar resultado do primeiro passe 6→2.
3. Voltar ao mesmo savestate e reiniciar script para CALIB:B com os mesmos comandos.
4. Comparar direção do deslocamento da bola, recepção observada, desvios e tempo em frames.

Não inferir que um modo é melhor com uma única tentativa. Não há medição validada de velocidade física da bola ou orientação interna da ROM; offsets dx/dy são apenas observacionais. A execução no BizHawk está pendente.
