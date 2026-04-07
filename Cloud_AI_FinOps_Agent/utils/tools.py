from datetime import date


def log_billing_anomaly(
    logging_client,
    agent_project_id,
    full_table_path,
    anomaly_type: str,
    severity: str,
    details: str,
) -> str:
    """
    Logs a billing anomaly or high-cost event to Google Cloud Logging.
    """
    logging_logger = logging_client.logger("billing-anomaly-detector")

    severity_map = {
        "HIGH": "ERROR",
        "MEDIUM": "WARNING",
        "LOW": "INFO",
        "URGENT": "CRITICAL",
    }

    final_severity = severity_map.get(severity.upper(), "WARNING")
    payload = {
        "message": f"FinOps Anomaly: {anomaly_type}",
        "details": details,
        "data_source": full_table_path,
        "detected_at": str(date.today()),
    }

    logging_logger.log_struct(
        payload,
        resource={
            "type": "global",
            "labels": {"project_id": agent_project_id},
        },
        severity=final_severity,
    )
    return f"""Successfully logged {anomaly_type} 
    to project {agent_project_id} with severity {final_severity}."""
