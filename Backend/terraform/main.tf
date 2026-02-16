terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "faltometro-ufrgs"
  region  = "southamerica-east1"
  zone    = "southamerica-east1-b"
}

resource "google_project_service" "project-services" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
  ])

  service = each.value
}

resource "google_artifact_registry_repository" "backend-image-repo" {
  location      = "southamerica-east1"
  repository_id = "backend-image"
  format        = "Docker"

  depends_on = [google_project_service.project-services]
}

resource "google_cloud_run_v2_service" "backend-service" {
  name     = "backend-service"
  location = "southamerica-east1"
  template {
    containers {
      image = "southamerica-east1-docker.pkg.dev/faltometro-ufrgs/backend-image/faltometro-ufrgs-backend:latest"
    }
  }
  deletion_protection = false

  depends_on = [google_artifact_registry_repository.backend-image-repo]
}

resource "google_cloud_run_v2_service_iam_member" "backend-service-public_access" {
  location = google_cloud_run_v2_service.backend-service.location
  name     = google_cloud_run_v2_service.backend-service.name
  member   = "allUsers"
  role     = "roles/run.invoker"
}
