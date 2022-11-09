# General
variable "project_id" {
  type    = string
}

variable "resource_regions" {
  type    = string
  default = "europe-west3"
}

variable "resource_zone" {
  type    = string
  default = "europe-west3"
}

variable "resource_location" {
  type    = string
  default = "EU"
}

# Cloud Storage

variable "bucket_name" {
  type    = string
  default = "test_bucket"
}

# Cloud Run

variable "container_image_url" {
  type    = string
  default = null
}

variable "container_image_version_tag" {
  type    = string
  default = "latest"
}