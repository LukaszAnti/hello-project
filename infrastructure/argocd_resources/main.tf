data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../gcp/terraform.tfstate" # Path to the GKE stage's state file
  }
}

data "terraform_remote_state" "argocd" {
  backend = "local"
  config = {
    path = "../argocd/terraform.tfstate" # Path to the GKE stage's state file
  }
}

provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.gke_cluster_endpoint}"
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.gke_cluster_ca_certificate)
  token                  = data.terraform_remote_state.gke.outputs.gke_token
}

resource "kubernetes_manifest" "parent_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "apps"
      namespace = "argocd"

    }
    spec = {
      project = "default"
      source = {
        repoURL        = "git@github.com/LukaszAnti/hello-project.git"
        path           = "k8s_manifests"
        targetRevision = "HEAD"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune     = true
          selfHeal  = true
        }
      }
    }
  }
}

