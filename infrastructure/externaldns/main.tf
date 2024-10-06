data "terraform_remote_state" "gke" {
  backend = "local"
  config = {
    path = "../gcp/terraform.tfstate"  # ścieżka do pliku tfstate z konfiguracją GKE
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

resource "google_dns_managed_zone" "primary" {
  name        = "app-portfolio-tech-zone"
  dns_name    = "app-portfolio.tech."
  description = "Managed zone for app-portfolio.tech"

  visibility = "public"

  project = var.project_id
}

resource "google_dns_record_set" "app_a_record" {
  name         = "app-portfolio.tech."
  managed_zone = google_dns_managed_zone.primary.name
  type         = "A"
  ttl          = 300

  rrdatas = [var.loadbalancer_ip]

}


