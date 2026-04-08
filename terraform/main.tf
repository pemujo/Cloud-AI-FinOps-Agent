# --- 1. DATA & METADATA LOOKUP ---

# Automatically read the Agent ID from the deployment JSON
locals {
  metadata_path = "${path.module}/../deployment_metadata.json"
  metadata      = jsondecode(file(local.metadata_path))
  
  # This grabs the full 'projects/.../reasoningEngines/...' path
  agent_full_id = local.metadata["remote_agent_engine_id"]
}

# Fetch project details (needed for the Project Number)
data "google_project" "project" {
  project_id = var.project_id
}

# Fetch the default compute service account for the Scheduler to use
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# --- 2. IAM PERMISSIONS ---

# Grant Cloud Scheduler permission to act as the Service Account
resource "google_service_account_iam_member" "scheduler_impersonate" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

# --- 3. MONITORING & ALERTS ---

resource "google_monitoring_notification_channel" "email_billing_alerts" {
  project      = var.project_id
  display_name = "Billing Anomaly Email Channel"
  type         = "email"
  labels       = { email_address = var.alert_email }
}

resource "google_monitoring_alert_policy" "billing_anomaly_alert" {
  project      = var.project_id
  display_name = "billing-anomaly-detector"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Log match condition"
    condition_matched_log {
      filter = "logName=\"projects/${var.project_id}/logs/billing-anomaly-detector\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
    auto_close = "604800s"
  }

  notification_channels = [
    google_monitoring_notification_channel.email_billing_alerts.name
  ]
}

# --- 4. SCHEDULER TRIGGER ---

resource "google_cloud_scheduler_job" "finops_agent_trigger" {
  name     = "finops-agent-trigger"
  schedule = "0 9 * * *" # Runs daily at 9:00 AM
  region   = var.region
  project  = var.project_id

  http_target {
    http_method = "POST"
    
    # Since agent_full_id is the full path from JSON, we just append the method
    uri = "https://${var.region}-aiplatform.googleapis.com/v1/${local.agent_full_id}:streamQuery"
    
    body = base64encode(jsonencode({
      class_method = "async_stream_query"
      input = {
        user_id = "scheduler_bot"
        message = "Run a standard billing audit for yesterday's costs and log any anomalies found."
      }
    }))

    headers = { "Content-Type" = "application/json" }

    oauth_token {
      service_account_email = data.google_compute_default_service_account.default.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  # This is the only dependency we keep to ensure IAM is ready before the job fires
  depends_on = [google_service_account_iam_member.scheduler_impersonate]
}