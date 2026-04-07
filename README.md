# 💰 FinOps Billing Agent

This agent allows users to query Google Cloud billing and cost data using natural language. It is built with [Google ADK](https://github.com/GoogleCloudPlatform/generative-ai/tree/main/gemini/agents/adk), Vertex AI Agent Engine, and BigQuery.

## 📊 Overview

The FinOps Billing Agent provides a conversational interface to your Google Cloud Billing data. It can:
*   Query SKU-level granularity costs.
*   Analyze billing trends and anomalies.
*   Log detected anomalies directly to Cloud Logging.
*   Provide insights into cost drivers.

---

## 🚀 Getting Started

### Recommended: Using Agent Starter Pack

The [Agent Starter Pack](https://github.com/GoogleCloudPlatform/agent-starter-pack) is the recommended way to create and deploy this agent.

```bash
export AGENT_NAME=my-billing-agent
export GOOGLE_CLOUD_PROJECT=your-project-id

# 1. Create your project using agent-starter-pack
uvx agent-starter-pack create ${AGENT_NAME} \
  -d agent_engine \
  -ag \
  -a local@Cloud-AI-FinOps-Agent

cd ${AGENT_NAME}

# 2. Setup billing data and IAM permissions
# This will prompt you to use existing data or create a sample dataset
make install

# 3. Deploy to Vertex AI Agent Engine
make backend
```

---

## 📋 Prerequisites

Before running the setup, ensure you have:

1.  **Python 3.10+** and `uv` installed (`pip install uv`).
2.  **gcloud CLI** authenticated:
    ```bash
    gcloud auth login
    gcloud auth application-default login
    ```
3.  **Billing Export:** A functional BigQuery billing export enabled.
    *   [Official Documentation](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
    *   **Note:** It can take 24-48 hours for data to appear after enablement.

---

## 🛠️ Manual Setup & Configuration

If you are not using the Agent Starter Pack, follow these steps:

### 1. Enable APIs
```bash
gcloud services enable \
    compute.googleapis.com \
    aiplatform.googleapis.com \
    logging.googleapis.com \
    monitoring.googleapis.com \
    cloudscheduler.googleapis.com \
    bigquery.googleapis.com \
    iam.googleapis.com \
    geminidataanalytics.googleapis.com \
    discoveryengine.googleapis.com \
    cloudresourcemanager.googleapis.com \
    serviceusage.googleapis.com \
    --project=$GOOGLE_CLOUD_PROJECT
```

### 2. Configure Environment
Copy the example environment file and fill in your details:
```bash
cp Cloud_AI_FinOps_Agent/.env.example Cloud_AI_FinOps_Agent/.env
```

### 3. Run Setup Scripts
```bash
# Setup BigQuery data (Sample or Existing)
make setup_billing_data

# Create and configure the Agent Service Account
make create_sa
```

---

## 🔑 Permissions & Roles

The `make create_sa` script creates a dedicated service account `cloud-ai-finops-agent-sa` with the following minimum required roles:

*   **Execution Project:**
    *   `roles/bigquery.jobUser`
    *   `roles/aiplatform.user`
    *   `roles/serviceusage.serviceUsageConsumer`
    *   `roles/geminidataanalytics.dataAgentStatelessUser`
    *   `roles/telemetry.writer`
*   **Billing Project (if different):**
    *   `roles/bigquery.dataViewer`

---

## ⚠️ Disclaimer

This agent sample is provided for illustrative purposes only and is not intended for production use. It serves as a basic example of an agent and a foundational starting point for development. 

Users are solely responsible for further development, testing, and security hardening before deployment in a live environment.
