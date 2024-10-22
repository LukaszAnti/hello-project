data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../gcp/terraform.tfstate" # Path to the GKE stage's state file
  }
}

provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.gke_cluster_endpoint}"
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.gke_cluster_ca_certificate)
  token                  = data.terraform_remote_state.gke.outputs.gke_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.terraform_remote_state.gke.outputs.gke_cluster_endpoint}"
    cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.gke_cluster_ca_certificate)
    token                  = data.terraform_remote_state.gke.outputs.gke_token
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_secret.argocd_repo_secret]
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.5.2"

  force_update   = true
  recreate_pods  = true

  values = [
    <<EOF
crds:
  install: false
server:
  service:
    type: LoadBalancer
redis:
  enabled: true
EOF
  ]
}

data "google_secret_manager_secret_version" "ssh_private_key" {
  secret  = "github-ssh-private-key"
  project = var.project_id
}

resource "kubernetes_secret" "argocd_repo_secret" {
  depends_on = [data.google_secret_manager_secret_version.ssh_private_key]
  metadata {
    name      = "github-ssh-repo-credentials"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    url            = "git@github.com:LukaszAnti/hello-project.git"
    type           = "git"
    name           = "hello_project_github"
    sshPrivateKey  = data.google_secret_manager_secret_version.ssh_private_key.secret_data
  }

  type = "Opaque"
}

