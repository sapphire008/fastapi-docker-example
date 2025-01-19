# Specify the Google Cloud provider
provider "google" {
  project     = "rinoa-dev"
  region      = "us-central1"
}

# Enable the Artifact Registry API (if not already enabled)
resource "google_project_service" "artifact_registry_api" {
  project = "rinoa-dev"
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

# Create an Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "docker_registry" {
  depends_on    = [google_project_service.artifact_registry_api]
  repository_id = "fastapi-example-docker"
  project       = "rinoa-dev"
  location      = "us-central1"
  format        = "DOCKER"
  description   = "A Docker container registry for my webapp"
}

# Output the repository URL
output "repository_url" {
  value = google_artifact_registry_repository.docker_registry.repository_id
  description = "The Artifact Registry repository URL"
}

# Enable Cloud Run API
resource "google_project_service" "cloud_run_api" {
  project = "rinoa-dev"
  service = "run.googleapis.com"

  disable_on_destroy = false
}