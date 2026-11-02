# PASS LV.1 — v0.9.10: pontuação WRAM passiva e gargalos

Base v0.9.9, recorde visual documentado: Time Score 35, Bonus Score 274, Total 309. **Sem alteração de roteamento ou finalização nesta etapa de instrumentação.**

A sonda passiva lê endereços candidatos reaproveitados do DRIBBLE: `0x01CF3` (u8 Time Score), `0x01CF8` (u16 little endian Bonus Score), `0x01CFA` (u16 little endian Total Score) e `0x0DC06` (cópia candidata de total). Amostra a cada 30 frames enquanto ARM ativo e captura adicionalmente a cada novo visitante e após 10/10. Arquivo: `csv/pass_score_wram_v0910.csv`. Campos incluem `arithmetic_ok` para `total=time+bonus`, `copy_ok`, mudanças e amostras estáveis. Mesmo que ambos sejam verdadeiros, a leitura ainda é **candidata** até correlação temporal com uma tela de YOUR RECORD; leitura residual é possível.

Em `csv/pass_autopass_v0813.csv` (ou arquivo da variável `auto_csv` da execução), evento `time_score_slow_segment` identifica intervalos >=180 frames entre novos jogadores, com número de visitados e relógio. Não desliga bot nem modifica rota. A próxima otimização temporal deve usar estes dados para comparação A/B em várias execuções.

Verificação antes do uso: análise sintática Lua, testes estáticos, depois teste real BizHawk. A execução é necessária para assegurar que o valor candidato 35/274/309 corresponde à tela e não persiste de tentativa anterior.
