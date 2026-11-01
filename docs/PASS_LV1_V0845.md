# PASS LV.1 v0.8.45 — ajuste do autoteste

A v0.8.44 exige 24 unidades WRAM de distância mínima entre portador e receptor. O autoteste em `pass_bridge_v083.lua` usava jogadores fictícios espaçados de 20 unidades (`id*20`), fazendo a verificação de passe rejeitar a geometria antes de gerar os três frames de Control Pad+B.

Apenas a fixture foi alterada para posições `id*40` e bola inicial `(240,0)` junto ao jogador 6. Assim, o receptor vizinho fica a 40 unidades, dentro do mínimo de 24 e do máximo padrão de 190. Mantêm-se as exigências do autoteste: posse estável, exatamente três frames com B e direcional simultâneo, uma única tentativa.

**Não houve mudança no controlador de jogo nem na política global de 24 unidades.** Validar reiniciando `main.lua` no BizHawk. As alterações da v0.8.44 permanecem.
