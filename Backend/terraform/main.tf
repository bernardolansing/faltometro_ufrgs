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

locals {
  project_id = "faltometro-ufrgs"
  region     = "southamerica-east1"
}

provider "google" {
  project = local.project_id
  region  = local.region
  zone    = "southamerica-east1-b"
}

// GCP APIs required to be enabled for this project.
resource "google_project_service" "project-services" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
  ])

  service = each.value
}

// Create a service account to be used by Cloud Run. A service account is a set of privilleges granted to its "members".
resource "google_service_account" "cloud-run-service-account" {
  account_id   = "cloud-run-service-account"
  display_name = "Google Cloud Run service account"
}

// Here we define which privilleges ("roles") are those. 
resource "google_project_iam_member" "cloud-run-service-account-roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor", // Allow access to Secrets Manager secrets.
  ])

  member  = google_service_account.cloud-run-service-account.member
  project = local.project_id
  role    = each.value
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
  scaling {
    min_instance_count = 0
  }
  template {
    service_account = google_service_account.cloud-run-service-account.email
    containers {
      // The URL pointing to the Docker image that runs the backend code. This is the most recent image pushed to the
      // "backend-image-repo" Artifact Registry repository. Please make sure to build the image using this URL (after
      // interpolation) as tag.
      image = "${local.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.backend-image-repo.repository_id}/faltometro-ufrgs-backend:latest"
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

// This creates a Secret Manager secret to store the production database connection string. At first, it'll be empty and
// you're going to have to set the connection string yourself manually. This spares us from caching it locally wherever
// the terraform deployment takes place.
resource "google_secret_manager_secret" "database-creds-secret" {
  secret_id = "database-creds-secret"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }

  depends_on = [google_project_service.project-services]
}
