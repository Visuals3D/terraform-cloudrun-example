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

resource "google_project_service" "cloudrun_api_service" {
  project            = var.project_id
  disable_on_destroy = false
  service            = "run.googleapis.com"
}

resource "google_project_service" "storage_api_service" {
  project            = var.project_id
  disable_on_destroy = false
  service            = "storage.googleapis.com"
}

# Service accounts

resource "google_service_account" "svc_cloudrun" {
  account_id   = "svccloudrun"
  display_name = "Cloud run service account with access to cloud storage"
}

# Cloud Storage

resource "google_storage_bucket" "test_bucket" {
  name          = "${var.bucket_name}_${var.project_id}"
  location      = var.resource_regions
  force_destroy = true
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.storage_api_service
  ]
}

# Give Cloud Run read and create persmission for Cloud Storage Bucket
resource "google_storage_bucket_iam_member" "gcs_viewer" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/storage.objectCreator"
  ])
  bucket = google_storage_bucket.test_bucket.id
  role   = each.key
  member = "serviceAccount:${google_service_account.svc_cloudrun.email}"
}

# Cloud run

resource "google_cloud_run_service" "cloudrun_storage_uploader" {

  name     = "cloudrun-storage-uploader"
  location = var.resource_regions

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  template {
    spec {
      containers {
        image = var.container_image_url == null ? "${lower(var.resource_location)}.gcr.io/${var.project_id}/storage-uploader:${var.container_image_version_tag}" : "${var.container_image_url}:${var.container_image_version_tag}"
        env {
          name = "BUCKET"
          value = google_storage_bucket.test_bucket.name
        }
      }
      service_account_name = google_service_account.svc_cloudrun.email
    }
  }


  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.cloudrun_api_service
  ]
}

resource "google_cloud_run_service_iam_member" "cloudrun_user_access" {
 service = google_cloud_run_service.cloudrun_storage_uploader.name
 location = google_cloud_run_service.cloudrun_storage_uploader.location
 project = google_cloud_run_service.cloudrun_storage_uploader.project
 role = "roles/run.invoker"
 member = "allUsers"
}

# Load Balancer

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.resource_regions
  cloud_run {
    service = google_cloud_run_service.cloudrun_storage_uploader.name
  }
}

module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.3"
  name    = "cloudrun-lb"
  project = var.project_id

  ssl = false
  #managed_ssl_certificate_domains = [var.domain]
  https_redirect = false
  labels         = { "traffic-endpoint" = "cloudrun-storage-uploader" }

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}



