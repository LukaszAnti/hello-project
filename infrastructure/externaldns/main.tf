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

resource "google_dns_managed_zone" "flask_project_zone" {
  name     = "flask-project-org-zone"
  dns_name = "flask-project.org."  
  description = "Managed zone for flask-project.org"
}

resource "google_dns_record_set" "flask_project_a_record" {
  name         = "flask-project.org."
  managed_zone = google_dns_managed_zone.flask_project_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = ["34.118.118.100"]  
}
