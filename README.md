# DESAFIO BOOTCAMP AVANTI

Este repositório contém scripts e arquivos de configuração para provisionar uma instância EC2 na AWS usando Terraform e configuração do Runner GitLab para executar pipelines CI/CD, subindo uma imagem docker com o web site Mundo Invertido na rede mundial

## Passo a Passo

### 1. Provisionamento da Instância EC2 com Terraform

Obs.: Terraform já está instalado e configurado para realizar provisionamento no Cloud Provider AWS

1. Clonar o repositório do projeto Mundo Invertido para o seu ambiente local. https://github.com/denilsonbonatti/mundo-invertido.git

2. Criação de um diretório para aquivos do `terraform`

3. Criar um arquivo *main.tf* para definição da configuração de infraestrutura do Cloud Provider

4. Criar um arquivo *ec2.tf* para definir as configurações da instância (EC2)

5. Criar um arquivo *securiry.group.tf* para definir a configuração do grupo de segurança, que controlam o tráfego de entrada e saída para instâncias EC2

6. Executar o comando `terraform init` para inicializar o projeto Terraform.

![Terraform Init](https://gitlab.com/GabrielOliver001/docker-mundo-invertido/-/raw/main/prints/Terraform_Init.jpg)


7. Execute o comando `terraform plan` para visualizar os recurso que serão provisionados.

![Terraform Plan](https://gitlab.com/GabrielOliver001/docker-mundo-invertido/-/raw/main/prints/Terraform_Plan.jpg)


8. Execute o comando `terraform apply` para aplicar as alterações e provisionar a instância EC2 na AWS.

![Terraform Apply](https://gitlab.com/GabrielOliver001/docker-mundo-invertido/-/raw/main/prints/Terraform_Apply.jpg)


9. Instância Provisionada

![Terraform Apply](https://gitlab.com/GabrielOliver001/docker-mundo-invertido/-/raw/main/prints/EC2.jpg)


## Comandos Terraform

- `terraform init`: O comando `terraform init` é usado para inicializar um diretório de trabalho do Terraform. Ele configura o ambiente do Terraform, incluindo a instalação de plugins necessários para trabalhar com provedores de infraestrutura. Isso garante que o Terraform esteja pronto para criar, modificar ou destruir recursos de infraestrutura.

- `terraform plan`: O comando `terraform plan` é usado para criar um plano de execução. Ele mostra as alterações que serão feitas na infraestrutura, sem realmente fazer essas alterações. Isso permite revisar as alterações propostas antes de aplicá-las.

- `terraform apply`: O comando `terraform apply` é usado para aplicar as alterações definidas nos arquivos de configuração do Terraform. Ele cria, atualiza ou remove recursos conforme necessário para atingir o estado desejado definido nos arquivos de configuração.



### 2. Configuração do GitLab Runner na Instância EC2

A configuração do Runner foi realizada de forma automatizada, configurada por script de execução no provisionamento da Instância, segue abaixo o script:

    sudo gitlab-runner register \
    --non-interactive \
    --executor shell \
    --url https://gitlab.com/ \
    --registration-token GR1348941VPCSXXXXXXXXXXXXXXXX \
    --tag-list "AWS-Apache"


Segue abaixo o arquivo `script.sh` completo para preparar a Instância AWS para receber a aplicação Web

    #!/bin/bash
    #Atualização da Instância
    sudo apt-get update 
    sudo apt-get upgrade -y

    #Instalação do Gitlab Runner
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
    sudo apt-get install gitlab-runner -y

    #Configuração de Registro do Runner com Gitlab.
    sudo gitlab-runner register \
    --non-interactive \
    --executor shell \
    --url https://gitlab.com/ \
    --registration-token GR1348941VPCSXXXXXXXXXXXXXXXX \
    --tag-list "AWS-Apache"

    #Instalação do Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo apt-get update
    sudo sh get-docker.sh

    #Permissão de uso do Docker para os User
    sudo usermod -aG docker gitlab-runner
    sudo usermod -aG docker ubuntu


## 3. Dockerfile

Este repositório contém um Dockerfile no diretório `App` para um projeto chamado "Mundo Invertido", que construirá uma imagem Docker baseada na imagem oficial do Apache HTTP Server (httpd) versão 2.4. O arquivo Dockerfile define a configuração do ambiente necessário para executar o projeto em conteiner.

Vamos entender cada instrução:

    FROM httpd:2.4
    WORKDIR /usr/local/apache2/htdocs/
    COPY . /usr/local/apache2/htdocs
    EXPOSE 80

1. `FROM httpd:2.4`: Esta linha define a imagem base para construir a nova imagem. Neste caso, está utilizando a imagem oficial do Apache HTTP Server versão 2.4.

2. `WORKDIR /usr/local/apache2/htdocs/`: Esta instrução define o diretório de trabalho dentro do contêiner, onde os arquivos do Apache serão copiados e onde o Apache irá servir os arquivos.

3. `COPY . /usr/local/apache2/htdocs`: Esta instrução copia todos os arquivos do diretório atual (no seu sistema de arquivos local, onde está executando o comando `docker build`) para o diretório de trabalho dentro do contêiner. Isso inclui todos os arquivos no diretório atual, que serão servidos pelo Apache.

4. `EXPOSE 80`: Esta instrução informa ao Docker que o contêiner escutará na porta 80. Embora isso não mapeie automaticamente a porta do host para a porta do contêiner, indica que o contêiner espera tráfego na porta 80.

Obs.: É necessário ter uma conta no _Dockerhub_ para armazenar imagens docker



## 4. Pipeline GitLab CI

O arquivo `.gitlab-ci.yml` define os estágios de build, push e deploy para o projeto "Mundo Invertido" no pipeline do GitLab CI.

    stages:
    - build
    - push
    - deploy

    build_imagem:
    stage: build
    tags:
        - AWS-Apache

    #Configuração de Login da Instância com Dockerhub
    before_script:
        - docker login -u $REGISTRY_USER -p $REGISTRY_PASS

    #Construção da Imagem
    script:
        - docker build -t gabrieloliver001/mundo-invertido:1.0 app/.

    #Envio da Imagem ao Registry
    push_imagem:
    stage: push
    tags:
        - AWS-Apache
    script:
        - docker push gabrieloliver001/mundo-invertido:1.0

    #Deploy da Aplicação Web
    deploy:
    stage: deploy
    needs:
        - push_imagem
    tags:
        - AWS-Apache
    script:
        - docker run -dti --name mundo-invertido -p 80:80 gabrieloliver001/mundo-invertido:1.0


Aqui está o que cada parte faz:

1. **stages**: Define as etapas (ou stages) do pipeline de CI/CD. Neste caso, temos três etapas: build, push e deploy.

2. **build_imagem**: Esta é uma job (ou tarefa) que pertence à etapa "build". É responsável por construir a imagem Docker da aplicação. O nome da job é `build_imagem`.

   - **tags**: Define as tags dos executores GitLab CI/CD nos quais essa job será executada. No caso, a job será executada em executores que possuem a tag `AWS-Apache`.
   
   - **before_script**: Define comandos a serem executados antes do script principal da job. Aqui, é feito o login no DockerHub usando as variáveis de ambiente `$REGISTRY_USER` e `$REGISTRY_PASS`.
   
   - **script**: O script principal da job. Aqui, é executado o comando `docker build` para construir a imagem Docker da aplicação, utilizando o diretório `app/` como contexto.

3. **push_imagem**: Job da etapa "push", responsável por enviar a imagem Docker construída para um registry (como o Docker Hub).

   - **tags**: Define as tags dos executores onde essa job será executada.
   
   - **script**: O script principal da job. Aqui, é executado o comando `docker push` para enviar a imagem Docker para o Docker Hub.

4. **deploy**: Job da etapa "deploy", responsável por fazer o deploy da aplicação.

   - **needs**: Define que essa job precisa que a job `push_imagem` seja bem-sucedida antes de ser executada.
   
   - **tags**: Define as tags dos executores onde essa job será executada.
   
   - **script**: O script principal da job. Aqui, é executado o comando `docker run` para iniciar um contêiner a partir da imagem Docker que foi enviada para o DockerHub na job anterior. O contêiner é iniciado com o nome `mundo-invertido` e é mapeado para a porta 80 do host.


Esse arquivo de configuração automatiza o processo de build, push e deploy de uma aplicação Docker usando o GitLab CI/CD.



![Web Site](https://gitlab.com/GabrielOliver001/docker-mundo-invertido/-/raw/main/prints/Pipeline.jpg)



## 5. Acessando o Web Site Mundo Invertido

Após o provisionamento da instância é gerado um Ip Público o qual será usado para acesso ao web site via protocolo http com a porta padrão (80). Neste exemplo o endereço de acesso será http://54.80.55.48/

![Web Site](https://gitlab.com/GabrielOliver001/docker-mundo-invertido/-/raw/main/prints/Mundo-Invertido.jpg)
