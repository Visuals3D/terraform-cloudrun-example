data "google_container_registry_registry" "gcr" {
    project = var.project_id
}

output "gcr_location" {
    value = data.google_container_registry_registry.gcr.registry_url
}