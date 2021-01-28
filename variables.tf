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
variable "NOMAD_VERSION" {
  default = "1.0.1"
}

variable "azure_location" {
  default = "West Europe"
}

