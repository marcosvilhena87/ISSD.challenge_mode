# Protocolo de reconhecimento e descoberta de memória

## Estado atual
Nenhum endereço de RAM do Challenge Mode foi validado. `validated_memory` deve ser utilizado **somente** após validação independente dos dados lidos; a biblioteca não atribui essa confiança automaticamente.

## Coleta proposta
1. Capturar snapshots de memória em menu principal, menu de desafios, Dribble LV1-LV4 e fora do Challenge Mode.
2. Repetir com Pass, Shoot, Defense, Corner Kick e Free Kick.
3. Isolar candidatos estáveis por modalidade e nível e descartar relógios, frames e ponteiros instáveis.
4. Confirmar comportamento em reinício, mudança de nível e nova sessão.
5. Registrar plataforma, ROM/hash, domínio WRAM, endereço, largura, sinal, endianidade, valores e capturas/CSV de evidência.
6. Implementar leitura BizHawk apenas para campos confirmados e incluir testes com amostras positivas/negativas.

## Campos para relatório futuro
`challenge_id,level,frame,game_state,time_remaining,score,success,failure`

Campos acima são um esquema proposto, não valores já identificados. Nenhum mecanismo de controle automático foi ativado.
