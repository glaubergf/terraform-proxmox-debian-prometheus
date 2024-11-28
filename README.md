---
Projeto: terraform-proxmox-debian-prometheus
Descrição: Provisionar um servidor Debian 12 (Bookworm) nocloud com o Terraform para ser instalado o 
           Prometheus. A automação irá baixar a última imagem do Debian nocloud, criar uma VM (template)
           no servidor Proxmox com o Qemu, copiar arquivos de configurações, instalar alguns pacotes,
           configurar o sistema, habilitar e iniciar o Prometheus.
Autor: Glauber GF (mcnd2)
Data: 2024-11-24
---

![Image](https://github.com/glaubergf/terraform-proxmox-debian-prometheus/blob/main/images/tf-pm-prometheus.png)

# Servidor Prometheus Debian no Proxmox com o Terraform

Esse projeto provisiona com o **Terraform** um servidor **Debian 12 (Bookworm) nocloud** no **Proxmox** com configurações do **cloud-init** para ser instalado o **Prometheus**.

O provisionamento irá baixar a última imagem do Debian nocloud, criar uma VM (template) via script no servidor Proxmox com o Qemu, copiar arquivos de configurações do cloud-init para o servidor Proxmox, configurar a VM a ser criada com o cloud-init, instalar pacotes, configurar o sistema, habilitar e iniciar o Prometheus.

## Debian

O **[Debian](https://www.debian.org/intro/index#community)** é um sistema operacional livre, desenvolvido e mantido pelo projeto Debian. Uma distribuição Linux livre com milhares de aplicativos para atender às necessidades dos(as) usuários(as).

Para saber mais sobre o Debian, visite a [página do projeto](https://www.debian.org/).

### Debian Cloud

O Debian que vamos usar no projeto é baseado no provedor **[Qemu](https://www.qemu.org/)**, usando como *VM simples amd64* a imagem do **[Debian noCloud](https://cloud.debian.org/)**.

Há imagens para diferentes provedores:

* azure : Otimizado para o ambiente Microsoft Azure;
* ec2 : Otimizado para o Amazon EC2;
* generic : deve ser executado em qualquer ambiente que use cloud-init, por exemplo, OpenStack, DigitalOcean e também em bare metal;
* genericcloud : Semelhante a generic. Deve rodar em qualquer ambiente virtualizado. É menor que generic ao excluir drivers para hardware físico;
* nocloud : Mais útil para testar o processo de build em si. Não tem cloud-init instalado, mas permite login root sem senha.

A escolha da imagem **_nocloud_** foi por ter encontrado problemas com a imagem *generic* e *genericcloud* que já vem com o cloud-init instalado, enfrentando problema de *kernel panic* no provisionamento da VM com o Terraform.

## Cloud-Init

Gerenciar e configurar instâncias e servidores de nuvem pode ser uma tarefa complexa e demorada. O **[Cloud-Init](https://cloudinit.readthedocs.io/en/latest/explanation/introduction.html#introduction)** é uma ferramenta de inicialização de código aberto que foi projetada para facilitar a instalação e execução de seus sistemas com o mínimo de esforço, já configurados de acordo com suas necessidades.

O cloud-init é o método de multidistribuição padrão da indústria para inicialização de instância de nuvem multiplataforma. Ele é suportado por todos os principais provedores de nuvem pública, sistemas de provisionamento para infraestrutura de nuvem privada e instalações bare-metal.

Durante a inicialização, o cloud-init identifica a nuvem em que está sendo executado e inicializa o sistema de acordo. As instâncias da nuvem serão automaticamente provisionadas durante a primeira inicialização com rede, armazenamento, chaves SSH, pacotes e vários outros aspectos do sistema já configurados.

Para saber mais sobre o cloud-init, visite a [página do projeto](https://cloudinit.readthedocs.io/en/latest/).

## Prometheus

O **[Prometheus](https://prometheus.io/docs/introduction/overview/)** é um kit de ferramentas de monitoramento e alerta de sistemas de código aberto originalmente criado no **_SoundCloud_**. Desde seu início em 2012, muitas empresas e organizações adotaram o Prometheus, e o projeto tem uma comunidade de desenvolvedores e usuários muito ativa. Agora é um projeto de código aberto independente e mantido independentemente de qualquer empresa. Para enfatizar isso e esclarecer a estrutura de governança do projeto, o Prometheus se juntou à **_Cloud Native Computing Foundation_** em 2016 como o segundo projeto hospedado, depois do **_Kubernetes_**.

### Características

As principais características do **Prometheus** são:

* um modelo de dados multidimensional com dados de séries temporais identificados pelo nome da métrica e pares chave/valor;
* PromQL, uma linguagem de consulta flexível para alavancar essa dimensionalidade;
* sem dependência de armazenamento distribuído; os nós de servidor único são autônomos;
* a coleta de séries temporais ocorre por meio de um modelo pull sobre HTTP;
* o envio de séries temporais é suportado por meio de um gateway intermediário;
* os alvos são descobertos por meio da descoberta de serviço ou configuração estática;
* vários modos de suporte de gráficos e painéis.

Para saber mais sobre o Prometheus, visite a [página do projeto](https://prometheus.io/).

## Terraform

O **[Terraform](https://www.terraform.io/)** é uma ferramenta de código aberto de *"infraestrutura como código"* criada pela HashiCorp, permite que os programadores criem, alterem e versionem a infraestrutura com segurança e eficiência.

Para saber mais sobre o Terraform, visite a [página do projeto](https://developer.hashicorp.com/terraform?product_intent=terraform).

## O Projeto

O projeto provisona com o Terraform uma máquina virtual (VM) Debian no Proxmox, utilizando o Cloud Init e scripts personalizados, configurando e inicializando o Prometheus.

### O Fluxo do processo:

* **Templates:** O Terraform gera arquivos de configuração (Cloud Init e rede) usando templates.

* **Arquivos Locais:** Esses arquivos são salvos localmente.

* **Transferência para o Proxmox:** Os arquivos são enviados para o Proxmox, onde são usados durante a criação da VM.

* **Criação da VM:** A VM é criada a partir de um template no Proxmox, utilizando os arquivos de configuração do Cloud Init para inicialização automática.

* **Execução de Scripts:** Após a criação, a VM recebe e executa scripts para configurações adicionais, como ajustar o MOTD.

### Estrutura do projeto:

    ➤➤➤ $ ls -1R 

    .:
    configs
    LICENSE
    notes
    output.tf
    provider.tf
    README.md
    security
    terraform.tfvars
    variables.tf
    vm_proxmox.tf   

    ./configs:
    cloud_config.yml
    config_motd.sh
    motd_prometheus
    network_config.yml
    vm_template.sh  

    ./notes:
    art_ascii_to_modt.txt   

    ./security:
    auth_proxmox.txt
    tf-proxmox_id_rsa
    tf-proxmox_id_rsa.pub

### Os arquivos

* **provider.tf**

Esse arquivo do Terraform configura o provedor Proxmox, especificando a versão e as credenciais de acesso à API do Proxmox.
    
    Ele usa variáveis para a URL da API, o ID e o token secreto da API, além de permitir conexões sem validação de HTTPS (caso o certificado não seja válido).

* **vm_proxmox.tf**

Esse arquivo Terraform automatiza a criação da VM no Proxmox.

    Configuração CloudInit: Processa arquivos de configuração (CloudInit e rede) e os  salva localmente.

    Transferência de arquivos: Envia os arquivos de configuração para o Proxmox.

    Execução de script no Proxmox: Copia e executa um script no Proxmox para preparar a VM.

    Criação da VM: Cria a VM no Proxmox usando um template, aplicando as configurações de   CloudInit.

    Provisionamento na VM: Após a criação, transfere e executa scripts dentro da VM via SSH.

* **variables.tf**

Esse arquivo define várias variáveis usadas no Terraform para configurar a máquina virtual (VM) no Proxmox.

    Credenciais do Proxmox: Variáveis para a URL, ID e segredo do token da API do Proxmox.

    Configurações da VM: Variáveis para o nome, IP, domínio, usuário e senha da VM.
    
    Recursos do Proxmox: Variáveis para o servidor Proxmox, nó do cluster, e armazenamento.

    Configuração de hardware da VM: Variáveis para memória, número de núcleos, tamanho de disco, endereço MAC, etc.

    Chaves SSH: Variáveis para chaves SSH pública e privada.

    Configuração de arquivos: Caminhos para arquivos de configuração do CloudInit, rede, scripts de template e scripts de MOTD.

* **terraform.tfvars**

Esse arquivo fornece os valores específicos que o Terraform utilizará para criar e  configurar a VM no Proxmox, usando as variáveis definidas anteriormente.

    Credenciais do Proxmox:

    proxmox_url: URL da API do Proxmox.
    proxmox_token_id: ID do token de API para autenticação.
    proxmox_token_secret: Segredo do token de API.

    Configurações da VM:

    vm_hostname: Nome do host da VM.
    vm_ip: Endereço IP da VM.
    vm_domain: Domínio da VM.
    vm_password: Senha do usuário da VM.
    vm_user: Nome do usuário na VM.

    Recursos do Proxmox:

    srv_proxmox: IP do servidor Proxmox.
    node: Nó do cluster Proxmox onde a VM será criada.
    template: Template de clonagem para a VM.

    Configurações de Hardware:

    vm_vmid: ID único da VM.
    vm_memory: Memória atribuída à VM (em MB).
    vm_cores: Número de núcleos de CPU para a VM.
    storage_proxmox: Tipo de armazenamento utilizado.
    vm_macaddr: Endereço MAC da rede da VM.
    disk_size: Tamanho do disco da VM (em GB).

    Chaves SSH:

    ssh_key: Caminho para a chave pública SSH.
    private_key: Caminho para a chave privada SSH.

    Arquivos de Configuração e Scripts:

    cloud_config_file: Caminho para o arquivo de configuração do CloudInit.
    network_config_file: Caminho para o arquivo de configuração de rede.
    vm_template_script_path: Caminho para o script de template da VM.
    config_motd_script_path: Caminho para o script de configuração do MOTD.
    motd_prometheus_path: Caminho para o arquivo de MOTD do Prometheus.

* **cloud_config.yml**

Esse arquivo fornece a configuração de provisionamento da imagem baseado no cloud-init.

    Pacotes: Instala prometheus, node-exporter e outros pacotes.
    Usuário: Cria usuário comum, grupos e autorizações SSH.
    Chpasswd: Gerencia senhas dos usuários.
    Lock_passwd: Desabilita senha root.
    Fqdn: Define o nome de domínio da VM.
    Power_state: Reinitia sistema após cloud-init.
    Timezone: Defini a zona horária.
    Runcmd: Executa comandos e scripts durante inicialização.

* **network_config.yml**

Este arquivo define as configurações de rede para a interface Ethernet.

    Não usar DHCP para obter endereço IP.
    Definir o endereço IP fixo.
    Definir uma rota padrão com destino "default" e porta de saída.
    Configurar os servidores de nomes DNS.

### Executar o projeto

Faça o clone do projeto, altere as variáveis nos arquivos de configurações de acordo com seu ambiente e no diretório raiz do projeto, execute os comandos **_terraform_** a seguir.

* **init** - *Preparar o diretório de trabalho para outros comandos.*

```
terraform init
```

* **plan** - *Mostrar as alterações exigidas pela configuração atual.*

```
terraform plan
```

* **apply** - *Criar ou atualizar a infraestrutura.*

```
terraform apply
```

* **destroy** - *Destruir a infraestrutura criada anteriormente.*

```
terraform destroy
```

Caso queira executar os comandos *apply* e *destroy* sem digitar **yes** para a confirmação, acrescente nos comandos o parâmetro **--auto-approve**, assim ao executar o comando não pedirá a interação de confirmação. Atenção! Não tem volta, rs!

* **--auto-approve** - *Ignorar a aprovação interativa do plano antes de aplicar.*

```
terraform apply --auto-approve
terraform destroy --auto-approve
```

* **--help** - *Para mais informações de comando do _terraform_, use o '--help'.*

```
terraform --help
```

## Licença

**GNU General Public License** (_Licença Pública Geral GNU_), **GNU GPL** ou simplesmente **GPL**.

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)

------

Copyright (c) 2024 Glauber GF (mcnd2)

Este programa é um software livre: você pode redistribuí-lo e/ou modificar
sob os termos da GNU General Public License conforme publicada por
a Free Software Foundation, seja a versão 3 da Licença, ou
(à sua escolha) qualquer versão posterior.

Este programa é distribuído na esperança de ser útil,
mas SEM QUALQUER GARANTIA; sem mesmo a garantia implícita de
COMERCIALIZAÇÃO ou ADEQUAÇÃO A UM DETERMINADO FIM. Veja o
GNU General Public License para mais detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU
junto com este programa. Caso contrário, consulte <https://www.gnu.org/licenses/>.

*

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>
