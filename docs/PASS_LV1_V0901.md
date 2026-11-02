# PASS LV.1 — v0.9.1: direção única no envio do passe

Base: v0.9.0, preservando a finalização adaptativa e a sequência de passes da v0.8.99.

Problema observado: no passe 2→3, as coordenadas davam dx negativo e dy positivo, logo DOWN era o eixo dominante, mas o controlador convencional enviou UP+B.

A v0.9.1 inspeciona o comando final imediatamente antes de `joypad.set(buttons,1)`: para qualquer B experimental (sem X), identifica o receptor da rotina especial ou `autopass.target` da convencional, calcula novamente a geometria WRAM e substitui os botões direcionais pela direção cardinal dominante, deixando B ativo. Os movimentos diagonais sem B permanecem inalterados. O chute X e o módulo de finalização são preservados.

O evento `pass_direction_output` registra direção calculada, direção anteriormente solicitada, botões finalmente enviados, dx/dy, distância, controlador e se houve correção. Se não houver receptor e coordenadas válidos, o controlador cancela o B e registra `pass_direction_blocked` em vez de enviar passe às cegas.

Validação dinâmica pendente: verificar especialmente 2→3 com DOWN+B e continuidade até 10/10 e chute X. O estado espacial não confirma sozinho o êxito oficial do desafio.
