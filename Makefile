.PHONY: setup_billing_data  create_sa deploy

install: setup_billing_data  create_sa

setup_billing_data:
	@uv run python scripts/setup_billing_data.py

create_sa:
	@uv run python scripts/create_sa.py

deploy:
	# Extract the SA from .env at runtime
	$(eval AGENT_SA := $(shell grep "^AGENT_SERVICE_ACCOUNT=" Cloud_AI_FinOps_Agent/.env | cut -d'=' -f2))
	$(eval G_PROJECT := $(shell grep "^GOOGLE_CLOUD_PROJECT=" Cloud_AI_FinOps_Agent/.env | cut -d'=' -f2))
	@echo "🚀 Deploying as $(AGENT_SA)..."
	(uv export --no-hashes --no-header --no-dev --no-emit-project --no-annotate > Cloud_AI_FinOps_Agent/app_utils/.requirements.txt 2>/dev/null || \
	uv export --no-hashes --no-header --no-dev --no-emit-project > Cloud_AI_FinOps_Agent/app_utils/.requirements.txt) && \
	uv run -m Cloud_AI_FinOps_Agent.app_utils.deploy \
		--project="$(G_PROJECT)" \
		--source-packages=./Cloud_AI_FinOps_Agent \
		--entrypoint-module=Cloud_AI_FinOps_Agent.agent_engine_app \
		--entrypoint-object=agent_engine \
		--requirements-file=Cloud_AI_FinOps_Agent/app_utils/.requirements.txt \
		--service-account="$(AGENT_SA)" \
		$(if $(AGENT_IDENTITY),--agent-identity) \
		$(if $(filter command line,$(origin SECRETS)),--set-secrets="$(SECRETS)")