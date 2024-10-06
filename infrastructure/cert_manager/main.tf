data "terraform_remote_state" "gke" {
  backend = "local"

  config = {
    path = "../gcp/terraform.tfstate"
  }
}

# Użyj Helm provider w Terraformie
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.gke.outputs.gke_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.gke_cluster_ca_certificate)
    token                  = data.terraform_remote_state.gke.outputs.gke_token
  }
}

# Zainstaluj Cert-managera
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

  create_namespace = false
  version          = "v1.13.0"
}
