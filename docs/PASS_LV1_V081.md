# PASS LV.1 v0.8.1 — direcional e B no mesmo frame

O operador confirmou que o passe só ocorre ao pressionar **Control Pad + B simultaneamente**. A v0.8.1 conserva escolha por proximidade e alinhamento da v0.8 e limita a uma tentativa por ARM.

## Fluxo

1. Localizar portador espacial candidato e receptor elegível mais próximo, com penalidade de desalinhamento.
2. Corrigir alinhamento por até 2 frames de direcional sem B, se necessário.
3. **Pressionar B e uma ou mais direções no mesmo frame**, por 3 frames. Para AUTO, usa dx/dy; se o alvo estiver dentro da zona morta de 12 unidades nos dois eixos, usa o eixo dominante, evitando B sozinho.
4. Soltar todos os botões e aguardar até 90 frames por mudança espacial.
5. Interromper sem repetir automaticamente caso não exista alvo ou direcional válido.

O modo `DIRECTION:NEUTRAL` é incompatível com o passe: o bot **não pressiona B** e registra `no_direction_for_pass`. Os botões somente são enviados após `PASSBTN:B`, `AUTO:ON` e `ARM`.

## Testar no BizHawk

Reinicie `main.lua` em PASS LV.1 e acrescente ao `txt/pass_bot_commands_v01.txt`:

```text
PASSBTN:B
DIRECTION:AUTO
AUTO:ON
ARM
```

No PowerShell, escreva as linhas no arquivo com `Add-Content` em vez de digitá-las como comandos. `AUTO:OFF` ou `STOP` soltam botões.

### Evidências

- `csv/pass_inputs_v081.csv`: um registro por frame de acionamento direcional ou B, mais eventos de escolha/falha. Colunas `up/down/left/right/B/X` representam os botões enviados a `joypad.set`.
- `csv/pass_auto_v06.csv`: receptor escolhido, eventos e resultado.
- `csv/pass_direction_v072.csv`: receptor observado e deslocamento.

Esses registros documentam a **saída solicitada à API do emulador**; não confirmam recepção válida no jogo. O modo AUTO não garante que o jogador pretendido receba a bola. A correção de dois frames também precisa de calibração. Sem chute automático nesta branch.

Teste estático: `python -m unittest discover -s tests -p "test_pass_v081_static.py" -v`.
