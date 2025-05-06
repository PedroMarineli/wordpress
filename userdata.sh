#!/bin/bash

# Log inicial
echo "Iniciando User Data..." >> /tmp/userdata.log

# Atualizar o sistema
echo "Atualizando sistema..." >> /tmp/userdata.log
sudo apt-get update -y >> /tmp/userdata.log 2>&1
sudo apt-get upgrade -y >> /tmp/userdata.log 2>&1

# Variáveis de configuração
FILE_SYSTEM_ID=fs-07d317c1d2b2ecb8c
EFS_MOUNT_POINT=/mnt/efs/wordpress
GIT_REPO_URL=https://github.com/PedroMarineli/wordpress.git
DB_HOST=wordpress-db.c8fk4ougqlv1.us-east-1.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=senha-segura
DB_NAME=wordpress

# Instalar dependências
echo "Instalando dependencias..." > /tmp/userdata.log
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    git >> /tmp/userdata.log 2>&1

# Montar o EFS 
echo "Montando efs..." >> /tmp/userdata.log
#cloud-config
package_update: true
package_upgrade: true
runcmd:
- yum install -y amazon-efs-utils
- apt-get -y install amazon-efs-utils
- yum install -y nfs-utils
- apt-get -y install nfs-common
- file_system_id_1=$FILE_SYSTEM_ID
- efs_mount_point_1=$EFS_MOUNT_POINT
- mkdir -p "${efs_mount_point_1}"
- test -f "/sbin/mount.efs" && printf "\n${file_system_id_1}:/ ${efs_mount_point_1} efs tls,_netdev\n" >> /etc/fstab || printf "\n${file_system_id_1}.efs.us-east-1.amazonaws.com:/ ${efs_mount_point_1} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0\n" >> /etc/fstab
- test -f "/sbin/mount.efs" && grep -ozP 'client-info]\nsource' '/etc/amazon/efs/efs-utils.conf'; if [[ $? == 1 ]]; then printf "\n[client-info]\nsource=liw\n" >> /etc/amazon/efs/efs-utils.conf; fi;
- retryCnt=15; waitTime=30; while true; do mount -a -t efs,nfs4 defaults; if [ $? = 0 ] || [ $retryCnt -lt 1 ]; then echo File system mounted successfully; break; fi; echo File system not available, retrying to mount.; ((retryCnt--)); sleep $waitTime; done;
# Instalar Docker
echo "Instalando docker..." >> /tmp/userdata.log
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >> /tmp/userdata.log 2>&1
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" >> /tmp/userdata.log 2>&1
sudo apt-get update -y >> /tmp/userdata.log 2>&1
sudo apt-get install -y docker-ce docker-ce-cli containerd.io >> /tmp/userdata.log 2>&1

# Instalar Docker Compose V2
echo "Instalando compose..." >> /tmp/userdata.log
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> /tmp/userdata.log 2>&1
sudo chmod +x /usr/local/bin/docker-compose >> /tmp/userdata.log 2>&1
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose >> /tmp/userdata.log 2>&1

# Clonar repositório
echo "Clonando repositorio..." >> /tmp/userdata.log
cd /
git clone $GIT_REPO_URL >> /tmp/userdata.log 2>&1
cd /wordpress

# Configurar .env
echo "Configurando env..." >> /tmp/userdata.log
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

# Iniciar os containers
echo "Iniciando containers..." >> /tmp/userdata.log
sudo docker-compose up -d >> /tmp/userdata.log 2>&1

# Verificação final
echo "Status do Docker Compose:" >> /tmp/userdata.log
sudo docker-compose ps >> /tmp/userdata.log 2>&1
