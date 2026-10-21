# Integração canônica com ISSD.mapping

Fonte de referência: [ISSD.mapping/docs/CHALLENGE_MODE.md](https://github.com/marcosvilhena87/ISSD.mapping/blob/main/docs/CHALLENGE_MODE.md).
Leitura consultada: 2026-10-21; SHA do arquivo de origem: `42b0bfd7f207043dc75bf18e3ceff6069dc64aa4`.

O módulo `lua/challenge/mapping.lua` é um adaptador local mínimo dos candidatos dessa fonte, **não** um catálogo canônico independente. Antes de mudar endereços ou sua classificação, consultar e atualizar `ISSD.mapping` primeiro. Revisar eventuais alterações posteriores do documento upstream.

| Campo | WRAM | Tratamento |
| --- | --- | --- |
| challenge_a | 0xD708 | hipótese, u8 |
| challenge_b | 0xE52C | hipótese, u8 |
| selected_level | 0x1550 | hipótese, u8 |
| legacy_level_a | 0xD70A | telemetria opcional, não decide nível |
| legacy_level_b | 0xE52E | telemetria opcional, não decide nível |

Codificação postulada: 0 DRIBBLE, 1 PASS, 2 SHOOT, 3 DEFENSE, 4 CORNER KICK, 5 FREE KICK; nível 0..3 corresponde a LV1..LV4.

Sem flag de presença de menu validada: `candidate` **não é reconhecimento**. Valores residuais podem ser exibidos em qualquer tela. Nunca iniciar inputs de bot com base nesses dados. Os testes existentes são sintéticos e não validam semântica WRAM.

ROM de referência documentada na origem: SHA-256 `d2fe66c1ce66c65ce14e478c94be2e616f9e2cad374b5783a6a64d3c1a99cfa9`; vínculo com as sessões originais não comprovado.

Próxima fase: registrar controles positivos e negativos com ROM/build identificados, capturas independentes e detecção de presença do menu.
