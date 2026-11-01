# PASS LV.1 v0.8.8 — recepção tardia e trajetória

Esta versão mantém a cadeia contínua v0.8.6, a prioridade 11 → 10 da v0.8.7, os três frames simultâneos de Control Pad + B e o chute automático desligado.

## Alterações
- Janela básica por distância: 90, 150 ou 210 frames.
- Se houver deslocamento da bola de pelo menos **8 unidades** e ainda não houver portador diferente confirmado no fim da janela, aguarda **até mais 90 frames**. O B **não é reenviado**.
- Se o monitor não confirmar a transferência após a janela extra, o controlador encerra de forma segura com `ball_moved_without_transfer`.
- Registra `first_motion_frame`, deslocamento, coordenadas da bola e distância ao alvo geométrico a cada dez frames na fase de espera.
- Registra divergência `receiver_mismatch` quando o portador espacial observado não corresponde ao alvo planejado, incluindo sinalização de chegada antecipada a 10/11.
- Corrige a impressão de deslocamento após a criação de um novo atuador, que antes podia informar incorretamente `0.00`.

## Telemetria

Os eventos adicionais ficam no arquivo `csv/pass_auto_v06.csv`: `flight_wait_extended`, `flight_sample`, `flight_summary`, `receiver_mismatch`.

## Experimento

Reinicie `main.lua` na branch v0.8.8, entre no PASS LV.1 e execute no PowerShell dentro do projeto:

```powershell
@(
 "PASSBTN:B"
 "DIRECTION:AUTO"
 "AUTO:ON"
 "ARM"
) | Add-Content ".\\txt\\pass_bot_commands_v01.txt"
```

A identificação espacial de portador e as trajetórias são candidatas inferidas, não validação oficial do objetivo. Teste no BizHawk e compare vídeo com os novos registros.
