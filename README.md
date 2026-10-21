# ISSD.challenge_mode

Projeto reiniciado do zero em 21/10/2026.

## Objetivo
Investigar e automatizar gradualmente os desafios do modo de treinamento de **International Superstar Soccer Deluxe (SNES)**, usando **BizHawk + Lua**.

## Estado atual
**v0.1 — estrutura inicial.** Nenhuma identificação de desafios, níveis, endereços de WRAM ou transições está validada nesta versão.

## Princípios
1. Registrar observações antes de implementar reconhecimento automático.
2. Separar hipótese, evidência reproduzida e mapeamento validado.
3. Não inferir desafio/nível apenas de valores isolados de memória.
4. Guardar experimentos em registros reproduzíveis com ROM, emulador, fase e resultado.
5. Manter o código deste repositório independente de projetos de bot até que a interface esteja estável.
6. Nunca incluir ROMs ou savestates protegidos por direitos autorais no repositório.

## Estrutura
- `lua/main.lua`: ponto de entrada mínimo, sem leitura de memória.
- `docs/ROADMAP.md`: etapas de implementação.
- `docs/EXPERIMENTOS.md`: protocolo de evidências.
- `tests/`: reservado para testes futuros.

## Primeira execução
Abra a ROM legitimamente obtida no BizHawk, use o console Lua e carregue `lua/main.lua`. O script apenas imprime uma mensagem para verificar a execução.

## Próximo experimento
Capturar observações separadas para **menu de treinamento, seleção do desafio, seleção do nível e desafio em execução**, sem pressupor qualquer endereço WRAM.

### Histórico
O reinício substituiu os arquivos da árvore ativa por uma base mínima, **preservando os commits anteriores no histórico Git**.
