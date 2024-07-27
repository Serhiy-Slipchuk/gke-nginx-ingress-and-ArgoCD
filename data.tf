data "google_client_config" "current" {
}

# daten des kubernetes cluster
data "google_container_cluster" "primary" {
  name     = var.name
  location = var.location
  project  = var.project
  depends_on = [
    google_container_cluster.primary
  ]
}
