variable "project_id" {
  description = "The GCP project ID"
  default = "rinoa-dev"
}

variable "region" {
  description = "The GCP region"
  default     = "us-central1"
}

variable "github_org" {
    description = "GitHub organization or user name"
    default = "sapphire008"
}

variable "github_repo" {
    description = "Name of the GitHub repository"
    default = "fastapi-docker-example"
}