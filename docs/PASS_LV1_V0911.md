# PASS LV.1 — v0.9.11

Base: v0.9.10, derivada da estratégia v0.9.9 (recorde visual de 309 pontos; Time Score 35).

## Passe de apoio com estimativa de custo
Mantém o mecanismo de passe de apoio existente, porém somente o ativa quando ambos os trechos (origem→apoio e apoio→alvo) estão dentro de 185 WRAM, desvio vertical ≤105, corredores do segundo passe desimpedidos, e a economia estimada em relação à caminhada for ≥35 unidades. Fórmula heurística: caminhada = distância direta + 220; apoio = distância até apoio + distância restante + 48. Valores não são segundos reais nem garantia de recepção. Quando rejeitado, registra `time_score_relay_rejected`. A política da v0.9.9 e suas rotas de fallback permanecem.

## Monitor de pontuação
Amplia o monitor WRAM v0.9.10: primeiro snapshot após ARM constitui base; resultado fresco exige mudança desse snapshot, valor total positivo, `time+bonus=total`, cópia em `0x0DC06` igual ao total e três amostras consecutivas da mesma combinação (coleta normal ~30 frames). Evento `pass_score_wram_correlated` significa **candidato consistente**, não prova automática da tela oficial do jogo. Valores de sessão anterior podem persistir e requerem comparação com tela, inclusive para resultados idênticos. Não altera memória do jogo.

## Verificação
Testes estáticos `tests/test_pass_v0911_static.py`; validação de sintaxe e dinâmica BizHawk ainda necessárias. Comparar ≥10 tentativas v0.9.9 vs. v0.9.11, sobretudo taxa de conclusão, Time Score médio e saídas de `time_score_relay_rejected`. Não alterar a finalização.
