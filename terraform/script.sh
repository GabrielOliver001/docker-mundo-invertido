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
