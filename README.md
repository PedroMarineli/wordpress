# Projeto Wordpress + RDS + EFS + ASG na AWS
---
![Passo a passo do projeto.](passoapasso)

---
### Vídeo para referência: [Compass OUL DevSecOps project](https://youtu.be/Z2CLUppdeBg)
### Resumo
- Configurar ambiente:
  - Criar VPC
  - Criar Security groups
  - Criar RDS
  - Criar EFS
  - Criar Load Balancer
  - Criar Target Group
- Criar AMI base:
  - Criar EC2
  - Atualizar sistema + dependências
  - Criar userdata + AMI
  - Testar userdata e AMI
- Criar Launch Template:
  - Criar EC2 a partir da AMI
  - Configurar Wordpress e EFS
  - Configurar userdata do Launch Template
  - Testar e criar o Launch Template
- Criar ASG:
  - Criar Auto Scaling Group
