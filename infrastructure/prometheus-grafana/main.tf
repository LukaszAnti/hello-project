data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../gcp/terraform.tfstate"  # ścieżka do pliku tfstate z konfiguracją GKE
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.terraform_remote_state.gke.outputs.gke_cluster_endpoint}"
    cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.gke_cluster_ca_certificate)
    token                  = data.terraform_remote_state.gke.outputs.gke_token
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "6.56.2"

  values = [
    <<EOF
    persistence:
      enabled: true
      storageClass: "standard"  # Zmienione na standard
      size: 10Gi
    EOF
  ]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "monitoring"
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "22.5.0"

  timeout    = 1200

  values = [
    <<EOF
    server:
      persistentVolume:
        enabled: true
        storageClass: "standard"  # Zmienione na standard
        size: 10Gi
      resources:
        requests:
          memory: "1Gi"
          cpu: "500m"
        limits:
          memory: "2Gi"
          cpu: "1"
    EOF
  ]
}


