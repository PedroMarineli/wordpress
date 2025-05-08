# Projeto Wordpress + RDS + EFS + ASG na AWS
---
![Passo a passo do projeto.](passoapasso)
---
### Vídeo para referência: [Compass OUL DevSecOps project](https://youtu.be/Z2CLUppdeBg)
---
### Resumo
- Configurar ambiente:
  - Criar VPC
 
    Necessário criar 1 vpc com 2 subnets públicas e 2 privadas, com 1 NAT Gateway em cada AZ privada referenciada pelo Target Group.
  - Criar Security groups
 
    Necessário criar 4 security groups: RDS, EFS, EC2 e Load Balancer. (configurações exatas mostradas no vídeo)
  - Criar RDS

    Criar banco MySql utilizando configurações voltadas para o tier gratuito, atentar-se em colocar as informações corretas nas variáveis do userdata do Launch       Template.
  - Criar EFS
 
    Zona de disponibilidade regional e modo de desempenho de uso geral, atentar-se em colocar as informações corretas nas variáveis do userdata do Launch              Template.
  - Criar Load Balancer

    Criar um Load Balancer de aplicação voltado para a internet, selecione suas subnets públicas.
  - Criar Target Group

    Protocolo HTTP na porta 80.
- Criar AMI base:
  - Criar EC2

    Utilizar configurações padrão com acesso a internet, apenas para servir de molde para a criação da AMI.
  - Atualizar sistema + dependências

    Atualize o sistema e instale as dependências do projeto para otimizar o tempo de inicialização do ASG. 
  - Criar userdata + AMI

    Crie o userdata da AMI (código abaixo).
  - Testar userdata e AMI
 
    Teste o userdata e se estiver tudo certo, crie a imagem.
- Criar Launch Template:
  - Criar EC2 a partir da AMI
 
    A partir da imagem criada instancie um maquina EC2 e verifique se está tudo certo.
  - Configurar Wordpress e EFS
 
    Configure o Wordpress com o git e docker compose e faça a montagem do sistema de arquivos.
  - Configurar userdata do Launch Template
 
    Crie o userdata com os comandos executados (código abaixo).
  - Testar e criar o Launch Template
 
    Teste o userdata e se estiver tudo certo, crie o launch template.
- Criar ASG:
  - Criar Auto Scaling Group

    Utilize o launch template criado, e selecione as zonas de disponibilidades e subnets.
#### Código:

##### compose.yaml
```yaml
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    env_file:
      - .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
```

##### userdata_ami.txt
```sh
#!/bin/bash

#Atualizar o sistema
sudo apt-get update -y
sudo apt-get upgrade -y

#Dependencias
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common git

#Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

#Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

##### userdata_launch_template.txt
```sh
#!/bin/bash

#Variaveis
FILE_SYSTEM_ID=  [seu dns do efs]
EFS_MOUNT_POINT=/mnt/efs/wordpress
GIT_REPO_URL=https://github.com/PedroMarineli/wordpress.git
DB_HOST= [seu db host]
DB_USER=admin
DB_PASSWORD=senha-segura
DB_NAME=wordpress

#Efs
sudo apt-get update
sudo apt-get install -y nfs-common
sudo mkdir -p $EFS_MOUNT_POINT
sudo mount -t nfs4 -o nfsvers=4.1 $FILE_SYSTEM_ID:/ $EFS_MOUNT_POINT
sudo chown -R www-data:www-data $EFS_MOUNT_POINT
sudo chmod -R 755 $EFS_MOUNT_POINT

#Git
cd /
git clone $GIT_REPO_URL
cd /wordpress

#.env
cat > .env <<EOL
WORDPRESS_DB_HOST=$DB_HOST
WORDPRESS_DB_USER=$DB_USER
WORDPRESS_DB_PASSWORD=$DB_PASSWORD
WORDPRESS_DB_NAME=$DB_NAME
WORDPRESS_CONFIG_EXTRA="
define('WP_HOME', 'http://' . \\\$_SERVER['HTTP_HOST']);
define('WP_SITEURL', 'http://' . \\\$_SERVER['HTTP_HOST']);
"
EOL

#Iniciar containers
sudo docker-compose up -d
```
