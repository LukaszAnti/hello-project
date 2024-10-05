output "gke_cluster_endpoint" {
  description = "The GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "gke_cluster_ca_certificate" {
  description = "The base64 encoded GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "gke_token" {
  description = "The token to authenticate to the GKE cluster"
  value       = data.google_client_config.default.access_token
  sensitive = true
}

