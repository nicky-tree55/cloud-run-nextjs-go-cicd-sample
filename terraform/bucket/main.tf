locals {
  bucket_name   = "cloud-run-ga-cicd-terraform-bucket"
  location      = "us-west1"
  storage_class = "REGIONAL"
}

resource "google_storage_bucket" "terraform-state-store" {
  name          = local.bucket_name
  location      = local.location
  storage_class = local.storage_class

  project = var.project_id

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 5
    }
  }
}