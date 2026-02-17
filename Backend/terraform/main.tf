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
  backend_image_name = "faltometro-ufrgs-backend"
  // The Docker image tag to be used by the Cloud Run Service. If new-backend-image-tag is specified, it uses it;
  // otherwise, the current tag in Terraform state is going to be used. This way, it's not necessary to provide the
  // current image tag along with its digest every time we want to apply and the Cloud Run Service is only going to be
  // updated when a new tag is provided.
  backend_image_tag = var.new-backend-image-tag == null ? lookup(data.terraform_remote_state.current_state.outputs, "current-backend-service-image") : var.new-backend-image-tag
}

variable "new-backend-image-tag" {
  type = string
  description = "If set, updates the Docker image tag to be used by the backend Cloud Run Service that runs our web server"
  default = null
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
  location      = local.region
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
      image = local.backend_image_tag
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

data "google_artifact_registry_docker_image" "latest-backend-image" {
  image_name    = local.backend_image_name
  location      = local.region
  repository_id = google_artifact_registry_repository.backend-image-repo.repository_id
}

data "terraform_remote_state" "current_state" {
  backend = "gcs"
  config = {
    bucket = "faltometro-ufrgs-terraform-state-bucket"
  }
}

output "current-backend-service-image" {
  description = "The digest of the currently in use Docker image running the Cloud Run web server"
  value = data.google_artifact_registry_docker_image.latest-backend-image.self_link
}
