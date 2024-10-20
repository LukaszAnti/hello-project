data "terraform_remote_state" "gke" {
  backend = "local"

  config = {
    path = "../gcp/terraform.tfstate"
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

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.11.3"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.16.1"

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "kubernetes_manifest" "letsencrypt_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "luki.antas@gmail.com"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "flask_project_cert" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "flask-project-cert-prod"
      namespace = "hello-app-namespace"
    }
    spec = {
      secretName = "flask-project-cert-secret"
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
      commonName = "flask-project.org"
      dnsNames = ["flask-project.org"]
    }
  }
}

resource "kubernetes_manifest" "flask_project_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "flask-project-ingress"
      namespace = "hello-app-namespace"
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"  # ClusterIssuer staging
      }
    }
    spec = {
      ingressClassName = "nginx"  # Klasa Ingressa
      tls = [{
        hosts = ["flask-project.org"]
        secretName = "flask-project-cert-secret"  # Sekret certyfikatu staging
      }]
      rules = [{
        host = "flask-project.org"
        http = {
          paths = [{
            path = "/"
            pathType = "Prefix"
            backend = {
              service = {
                name = "hello-app"  # Nazwa Twojej aplikacji
                port = {
                  number = 80  # Port aplikacji
                }
              }
            }
          }]
        }
      }]
    }
  }
}













