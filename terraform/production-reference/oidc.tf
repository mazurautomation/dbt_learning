# ============================================================
# PRODUCTION REFERENCE ONLY
#
# Requires:
# - full Databricks account
# - account-level API access
# - Databricks service principal
# - exact GitHub OIDC subject observed from GitHub Actions
#
# Do not apply in Databricks Free Edition.
# ============================================================

variable "github_oidc_audience" {
  description = "Expected GitHub OIDC audience."
  type        = string
}

variable "github_oidc_subject" {
  description = "Exact GitHub OIDC sub claim for the prod environment."
  type        = string
}


resource "databricks_service_principal_federation_policy" "github_prod" {

  # In a real deployment this resource must use the
  # account-level Databricks provider.

  service_principal_id = databricks_service_principal.dbt_deployer.id

  policy_id = "github-prod"

  description = "GitHub Actions production deployment."

  oidc_policy = {
    issuer = "https://token.actions.githubusercontent.com"

    audiences = [
      var.github_oidc_audience
    ]

    subject_claim = "sub"
    subject       = var.github_oidc_subject
  }
}