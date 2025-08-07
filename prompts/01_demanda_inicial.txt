a proposta na qual vamos trabalhar agora é a seguinte: tenho diversos sistemas pequenos, a maioria em Laravel, rodando em servidores AWS. Atualmente, uma única EC2 t3a.small consegue tranquilamente suportar todos estes conteineres. A EC2 é baseada em debian.

o que eu preciso é um sistema de contêineres com pelo menos três contêineres: 
 - nginx, que receberá requisições via HTTP e HTTPS
 - uma aplicação Laravel, com todos os pré-requisitos (do Laravel e da Aplicação) instalados
 - um banco de dados MySQL na última versão

À medida que as aplicações forem sendo necessárias, novos contêineres de aplicação serão adicionados, sempre recebendo requisições a partir do nginx. Ocasionalmente, novos conteineres de bancos de dados serão necessários como, por exemplo, ao ser necessário uma versão legada do MySQL.

Os bancos de dados devem armazenar dados em volumes mapeados para diretórios do host (a EC2), acessível a partir do usuário local. O diretório de trabalho na EC2 será /sistemas, tanto para os bancos como para os arquivos e scripts necessários.

Cada conteiner deve ter sua própria versão do PHP, pois há sistemas legados que só rodam em PHP 5.6. Estas versões são independentes. Pode ser usado PHP-FPM, ou uma forma que julgar mais adequada. Lembre de evitar conflitos de portas, caso estas portas sejam mapeadas para as do Host (não sei se isso será necessário)

O sistema de conteineres deve subir sozinho ao se ligar a máquina. Todos os contêineres envolvidos devem ficar na mesma rede docker. Deve ser possível (e fácil) instalar novos contêineres com aplicações, sem que seja necessário derrubar todas as outras (ou que a interrupção seja pequena). Ocasionalmente, uma aplicação pode atingir um nível de utilização que justifique migrar para outro serviço aws mais adequado ou inserir um load balancer no processo. Creio ser esse um pensamento futuro e não atual.

A seguir (não nesta demanda), depois de todo o sistema rodando, vamos trabalhar no deploy automático a partir de github actions. Para agora vamos dar os primeiros passos. Se houver alguma pergunta que julgue necessária antes de iniciar a tarefa, por favor, pergunte.