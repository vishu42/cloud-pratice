# Configure Terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.43.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  tenant_id = "1c721276-b529-4426-8bd0-29192fb2b12a"
}


provider "helm" {
  kubernetes {
    host                   = local.host
    cluster_ca_certificate = local.cluster_ca_certificate
    client_key             = local.client_key
    client_certificate     = local.client_certificate
    token                  = ""
  }
}


# initialize kubernetes provider
provider "kubernetes" {
  host                   = local.host
  cluster_ca_certificate = local.cluster_ca_certificate
  client_key             = local.client_key
  client_certificate     = local.client_certificate
  token                  = ""
}

provider "kubectl" {
  host                   = local.host
  cluster_ca_certificate = local.cluster_ca_certificate
  client_key             = local.client_key
  client_certificate     = local.client_certificate
  token                  = ""
}
