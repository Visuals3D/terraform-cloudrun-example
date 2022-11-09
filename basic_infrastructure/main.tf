terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}


provider "google" {
  project = var.project_id
  region  = var.resource_regions
  zone    = var.resource_zone
}

# Activate Google Apis

resource "google_project_service" "containerregistry_api_service" {
  project            = var.project_id
  disable_on_destroy = false
  service            = "containerregistry.googleapis.com"
}

# Google Container Registry

resource "google_container_registry" "container_registry" {
  project    = var.project_id
  location   = var.resource_location
  depends_on = [google_project_service.containerregistry_api_service]
}

resource "google_service_account" "gcr_service_account" {
  account_id = "gcr-pusher"
  display_name = "Container Registry Pusher"  
  depends_on = [google_project_service.containerregistry_api_service]
}

resource "google_storage_bucket_iam_member" "gcr_admin" {
  bucket = google_container_registry.container_registry.id
  role = "roles/storage.admin"
  member =  "serviceAccount:${google_service_account.gcr_service_account.email}"
}