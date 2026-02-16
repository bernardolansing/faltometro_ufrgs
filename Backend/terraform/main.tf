terraform {
  backend "gcs" {
    bucket = "faltometro-ufrgs-terraform-state-bucket" // This bucket is going to be used to store the Terraform state.
    // It can't be created by Terraform itself, so this bucket was created manually. It is very important that this
    // bucket is protected from public access through IAM policies.
  }

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

// GCP APIs required to be enabled for this project.
resource "google_project_service" "project-services" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
  ])

  service = each.value
}

// This uses Google Artifact Registry to create a Docker image repository. The images to be stored there run our web
// server. The "latest" image is the one to be used.
resource "google_artifact_registry_repository" "backend-image-repo" {
  location      = "southamerica-east1"
  repository_id = "backend-image"
  format        = "Docker"

  depends_on = [google_project_service.project-services]
}

// A Cloud Run Service that executes our backend code. It'll run a Docker container from the latest image in the
// repository declared above.
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

// This creates a policy that allows public access to the backend GCR service.
resource "google_cloud_run_v2_service_iam_member" "backend-service-public-access" {
  location = google_cloud_run_v2_service.backend-service.location
  name     = google_cloud_run_v2_service.backend-service.name
  member   = "allUsers"
  role     = "roles/run.invoker"
}
