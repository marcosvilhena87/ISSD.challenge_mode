# Roadmap

## Fase 0 — Base limpa (v0.1)
- [x] Substituir árvore ativa por estrutura mínima.
- [x] Preservar o histórico Git.
- [x] Criar entrada Lua independente de endereços.

## Fase 1 — Observação e coleta
- [ ] Confirmar versão/hash da ROM e versão do BizHawk.
- [ ] Documentar manualmente telas do Training/Challenge Mode.
- [ ] Registrar sequência de transições e eventos operados pelo usuário.
- [ ] Criar capturador de estados com metadados e timestamps/frames.

## Fase 2 — Descoberta
- [ ] Comparar capturas de menu, desafio e nível.
- [ ] Identificar candidatos WRAM por correlação e repetibilidade.
- [ ] Testar positivos e negativos, inclusive transições rápidas.

## Fase 3 — Reconhecedor
- [ ] Emitir `unknown` em estados ambíguos.
- [ ] Validar reconhecimento com testes e capturas independentes.
- [ ] Expor API estável de estado do desafio.

## Fase 4 — Automação
- [ ] Definir interface entre reconhecimento e controlador.
- [ ] Automatizar um desafio por vez, com telemetria e segurança.
