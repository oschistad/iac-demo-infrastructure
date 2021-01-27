variable "subscription_id" {}
variable "client_id" {}
variable "tenant_id" {}
variable "client_secret" {}
variable "tfe_orgname" {
  default = "aztekdemo"
}
variable "vm_size" {
  default = "Standard_D2s_v3"
}

locals {
  cloudinit= <<EOT
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker myuser
EOT

}