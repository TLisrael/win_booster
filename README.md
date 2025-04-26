# Otimizador para Windows


## Funcionaalidades
- Desativa sergiços desnecessários que consomem recursos
- Limpeza de arquivos temporarios (temp user, temp system, appdata local, prefetch...)
- Remove aplicativos desnecessários que são padrão do Windows
- Desabilita inicialização hibrida e hibernação
- Verifica integridade do sistema com SFC /SCANNOW e DISM


## Como utilizar
Para utilizar, basta executar o arquivo PS1 com o POWESHELL como administrador


Script pretende automatizar o processo de otimização de máquinas com intervenção minima.


PS: O programa altera configurações do sistema, portanto, é sempre bom ativar o PONTO DE RESTAURAÇÃO. O proprio script cria um ponto de restauração e backup, mas se estivar desativado em seu sistema, esse processo não será feito
