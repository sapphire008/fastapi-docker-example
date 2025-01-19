# Specify the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable the Artifact Registry API (if not already enabled)
resource "google_project_service" "artifact_registry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

# Enable the IAM Service Account Credentials API
resource "google_project_service" "iam_credentials_api" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"

  disable_on_destroy = false
}

# Create an Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "docker_registry" {
  depends_on    = [google_project_service.artifact_registry_api]
  repository_id = "fastapi-example-docker"
  project       = var.project_id
  location      = var.region
  format        = "DOCKER"
  description   = "A Docker container registry for my webapp"
}

# Output the repository URL
output "repository_url" {
  value       = google_artifact_registry_repository.docker_registry.repository_id
  description = "The Artifact Registry repository URL"
}

# Enable Cloud Run API
resource "google_project_service" "cloud_run_api" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_actions_pool" {
  provider                  = google
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
}

# Create the Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_actions_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "Provider for GitHub Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "assertion.repository==\"${var.github_org}/${var.github_repo}\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

}

# Create the Service Account
resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Deployer"
}

# Assign Artifact Registry Writer role to the service account
resource "google_artifact_registry_repository_iam_member" "github_deployer_artifact_access" {
  repository = google_artifact_registry_repository.docker_registry.name
  location   = var.region
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github_deployer.email}"
}

# Allow GitHub Actions to Impersonate the Service Account
resource "google_service_account_iam_member" "github_actions_impersonation" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member = join("", ["principalSet://iam.googleapis.com/",
    "${google_iam_workload_identity_pool.github_actions_pool.name}/",
    "attribute.repository/${var.github_org}/${var.github_repo}"
  ])
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_actions_provider.name
  description = "Workload Identity Provider for GitHub Actions"
}

output "service_account_email" {
  value       = google_service_account.github_deployer.email
  description = "Email of the GitHub Deployer Service Account"
}
