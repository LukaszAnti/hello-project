# Google Provider
provider "google" {
  credentials = file("/home/anti/app_pro/infrastructure/gcp/terraform-key.json")
  project     = var.project_id
  region      = var.region
}

# Google Client Config for Kubernetes provider
data "google_client_config" "default" {}

# GKE Credentials
resource "null_resource" "get_credentials" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region europe-central2 --project ${var.project_id}"
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  initial_node_count = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  node_config {
    preemptible = true
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  min_master_version = "1.27"
  deletion_protection = false
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    preemptible = true
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  autoscaling {
    min_node_count = 3
    max_node_count = 5
  }
}


# VPC and Subnetwork setup
resource "google_compute_network" "vpc_network" {
  name = "gke-network"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc_network.name
  region        = var.region
}

resource "google_artifact_registry_repository" "amazing_project_repo" {
  provider       = google
  location       = "europe-central2"
  repository_id  = "amazing-project-repo"
  description    = "Docker repository for Flask app"
  format         = "DOCKER"
}
