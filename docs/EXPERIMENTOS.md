# Protocolo de experimentos

Todo experimento deve registrar:
- Versão da ROM e hash, versão do BizHawk e core utilizado.
- Data, identificador da sessão e sequência de frames.
- Estado visível, ação realizada e resultado observado.
- Captura antes/depois da mudança, sem presumir endereço de memória.
- Hipótese testada e evidência contrária.

## Níveis de confiança
- **Hipótese:** observação isolada, ainda não reproduzida.
- **Reproduzido:** repetido no mesmo ambiente com controles.
- **Validado:** reproduzido em sessões independentes, com testes negativos.

Nunca elevar `hipótese` a `validado` apenas porque um valor coincide com uma tela.
