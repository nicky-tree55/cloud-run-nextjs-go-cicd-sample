# iamcredentialのAPIを有効化
resource "google_project_service" "iamcredentials" {
  service = "iamcredentials.googleapis.com"
  project = var.project_id
}
# Artifact RegistryのAPIを有効化
resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
  project = var.project_id
}

# Cloud RunのqAPIを有効化
resource "google_project_service" "cloudrun" {
  service = "run.googleapis.com"
  project = var.project_id
}

# Cloud Runのサービスアカウントを作成
resource "google_service_account" "operation_account" {
  account_id                   = var.operation_sa_id
  display_name                 = var.operation_sa_display_name
  description                  = "operation Account for Cloud Run"
  project                      = var.project_id
  create_ignore_already_exists = true
}

# ビルド用のサービスアカウントを作成
resource "google_service_account" "build_account" {
  account_id                   = var.build_sa_id
  display_name                 = var.build_sa_display_name
  description                  = "Service Account for Build"
  project                      = var.project_id
  create_ignore_already_exists = true
}

# ワークロードアイデンティティプールを作成
resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = var.workload_identity_pool_id
  project                   = var.project_id
}

# ワークロードアイデンティティプールプロバイダを作成
resource "google_iam_workload_identity_pool_provider" "main" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id
  display_name                       = var.workload_identity_provider_id
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  # See. https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token
  attribute_mapping = {
    "google.subject"  = "assertion.sub"
    "attribute.owner" = "assertion.repository_owner"
  }
  attribute_condition = "attribute.owner==\"${var.github_repo_owner}\""
  project             = google_iam_workload_identity_pool.main.project
}

# ワークロードアイデンティティプールプロバイダにサービスアカウントを紐付け
resource "google_service_account_iam_member" "workload_identity_iam_build" {
  service_account_id = google_service_account.build_account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.owner/${var.github_repo_owner}"
}

# ビルド用のサービスアカウントにCloud Runへのデプロイ権限を付与
resource "google_project_iam_member" "build_cloud_run_dev" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.build_account.email}"
}

# ビルド用のサービスアカウントにリソースの作成権限を付与
resource "google_project_iam_member" "build_resource_create" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.build_account.email}"
}

# ビルド用のサービスアカウントにCloud Strageの編集権限を付与（tfstate格納用）
resource "google_project_iam_member" "build_cloud_storage_edit" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.build_account.email}"
}

# ビルド用のサービスアカウントにCloud RunへのIAMポリシー設定権限を付与
resource "google_project_iam_custom_role" "custom_role_set_iam_policy" {
  role_id     = "customRunPolicyRole"
  title       = "Custom Run Policy Role"
  description = "A custom role to set IAM policies for Cloud Run"
  permissions = [
    "run.services.setIamPolicy"
  ]
  project = var.project_id
}

resource "google_project_iam_member" "build_account_custom_permissions" {
  project = google_project_iam_custom_role.custom_role_set_iam_policy.project
  member  = "serviceAccount:${google_service_account.build_account.email}"
  role    = google_project_iam_custom_role.custom_role_set_iam_policy.name
}

# Ariifact Registryへのリポジトリを作成
resource "google_artifact_registry_repository" "repo" {
  depends_on    = [google_project_service.artifactregistry]
  repository_id = var.artifact_registry_repository_id
  location      = var.location
  project       = var.project_id
  format        = "DOCKER" # or any other valid format like "MAVEN", "NPM", etc.
  cleanup_policies {
    action = "KEEP"
    id     = "keep-2gen"

    most_recent_versions {
      keep_count = 2
    }
  }
  cleanup_policies {
    action = "DELETE"
    id     = "delete-any"

    condition {
    }
  }
}

# ビルド用のサービスアカウントにArtifact Registryへの管理者権限を付与
resource "google_project_iam_member" "build_af_write_create" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.build_account.email}"
}

# ビルド用のサービスアカウントにArtifact Registryへの読み込み権限を付与
resource "google_project_iam_member" "build_af_read_create" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.build_account.email}"
}


output "GCP_PROJECT_ID" {
  value       = var.project_id
  description = "GCP Project ID"
}

output "GCP_REGION" {
  value       = var.location
  description = "GCP Location"
}

output "ARTIFACT_REPO" {
  value       = google_artifact_registry_repository.repo.repository_id
  description = "Artifact Registry Repository ID"
}

output "BUILD_ACCOUNT" {
  value       = google_service_account.build_account.email
  description = "Build Service Account email"
}

output "OPERATION_ACCOUNT" {
  value       = google_service_account.operation_account.email
  description = "Operation Service Account email"
}

output "WORKLOAD_IDENTITY_PROVIDER" {
  value       = google_iam_workload_identity_pool_provider.main.name
  description = "Workload Identity Pool Provider Name"
}

