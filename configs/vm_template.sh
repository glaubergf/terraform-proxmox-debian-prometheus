#!/bin/bash

## Script para criar imagem de template em QCOW2 no servidor Proxmox.
# Autor: Glauber GF (@mcnd2)
# Data: 24-11-2024

# Instalar no servidor Proxmox o pacote 'libguestfs-tools' para manipulação de imagens QCOW2.
if ! dpkg -l | grep -q libguestfs-tools; then
    apt update -y && apt install libguestfs-tools -y
else
    echo "libguestfs-tools já está instalado."
fi

# Imagens (https://cloud.debian.org/):
# - generic: Deve rodar em qualquer ambiente usando cloud-init, por exemplo:
#   OpenStack, DigitalOcean e também em bare metal.
# - genericcloud: Semelhante ao generic. Deve rodar em qualquer ambiente virtualizado.
#   É menor que `generic` ao excluir drivers para hardware físico.
# - nocloud: Mais útil para testar o próprio processo de build.
#   Não tem cloud-init instalado, mas permite login root sem senha.

# Variáveis:
URL=https://cdimage.debian.org/cdimage/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2
IMAGE=debian-12-nocloud-amd64
NAME=bookworm-nocloud
STORAGE=local
VMID=2000

# Verificar se o template com nome $NAME já existe, se não, continuar com o script.
if qm list | grep -q "$NAME"; then
  echo "Template $NAME já existe."
  exit 0
fi

# Baixar a imagem do Sistema Operacional "nocloud" em "/var/lib/vz/template/qemu".
cd /var/lib/vz/template/qemu/
rm -r $IMAGE.qcow2
wget $URL

# Instalar o 'cloud-init', o 'qemu-guest-agent' e configurar.
virt-customize -a $IMAGE.qcow2 --install cloud-init
virt-customize -a $IMAGE.qcow2 --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent.service' \
  --run-command 'systemctl start qemu-guest-agent.service'

# Apagar o conteúdo do arquivo /etc/machine-id, que é usado para gerar um ID único da máquina, evitando conflito.
virt-customize -a $IMAGE.qcow2 --truncate /etc/machine-id

# Criar uma nova instância de VM no Proxmox.
qm create $VMID -name $NAME -memory 1024 -cores 1 -sockets 1 -net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci

# Listar armazenamento disponível no Proxmox.
#pvesh get /storage

# Importar a imagem cloud do Debian para o armazenamento Proxmox (local).
qm importdisk $VMID /var/lib/vz/template/qemu/$IMAGE.qcow2 $STORAGE

# Anexar o disco à VM.
qm set $VMID -scsihw virtio-scsi-pci -scsi0 $STORAGE:$VMID/vm-$VMID-disk-0.raw

# Adicionar saída serial (se usar Openstack ou para monitoramento).
#qm set $VMID -serial0 socket

# Definir o "bootdisk" para o disco Debian Cloud importado.
qm set $VMID -boot c -bootdisk scsi0

# Habilitar o Qemu agent para controle remoto da VM.
qm set $VMID -agent 1

# Permitir "hotplugging" de rede, USB e discos.
qm set $VMID -hotplug disk,network,usb

# Adicionar uma única vCPU para a VM (por enquanto).
qm set $VMID -vcpus 1

# Adicionar uma saída de vídeo para a VM.
qm set $VMID -vga qxl

# Adicionar o disco cloud-init (para que o Cloud-init configure a VM automaticamente).
qm set $VMID -ide2 $STORAGE:cloudinit #,media=cdrom

# Aumentar o tamanho do disco de inicialização (se necessário).
# O tamanho padrão pode ser pequeno, por isso, é bom adicionar mais espaço.
qm disk resize $VMID scsi0 +4G

# Adicionar tags à VM.
#qm set $VMID -tags "template,cloudinit"

# Converter a VM para o modelo, tornando-a uma template.
qm template $VMID
