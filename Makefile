PROFILE ?= integration_tests
DBTF = ~/.local/bin/dbt # Note: MacOS path to dbt-fusion. In make-file, dotfiles aren't loaded, so we don't have access to aliases.
# See https://docs.getdbt.com/docs/fusion/install-fusion-cli

.PHONY: setup test test-fusion
setup: 
	@if ! command -v poetry &> /dev/null; then \
		echo "Error: poetry not found. Please install poetry first."; \
		echo "See: https://python-poetry.org/docs/#installation"; \
		exit 1; \
	fi
	@echo "Installing dependencies with Poetry..."
	poetry install

test: setup ## Run integration tests with dbt-core
	@if [ ! -f "integration_tests/profiles.yml" ]; then \
		echo "Error: profiles.yml not found in integration_tests/"; \
		echo "Please create profiles.yml with your BigQuery configuration."; \
		exit 1; \
	fi
	@echo "Running integration tests with dbt-core..."
	cd integration_tests && poetry run dbt deps --profile $(PROFILE)
	cd integration_tests && poetry run dbt seed --profile $(PROFILE)
	cd integration_tests && poetry run dbt run --profile $(PROFILE) --select models/ml --select models/ml
	cd integration_tests && poetry run dbt run --profile $(PROFILE) --exclude models/ml
	cd integration_tests && poetry run dbt test --profile $(PROFILE) 

test-fusion: ## Run integration tests with dbt-fusion
	@if [ ! -f "integration_tests/profiles.yml" ]; then \
		echo "Error: profiles.yml not found in integration_tests/"; \
		echo "Please create profiles.yml with your BigQuery configuration."; \
		exit 1; \
	fi
	@echo "Running integration tests with dbt-fusion..."
	cd integration_tests && $(DBTF) deps --profile $(PROFILE)
	cd integration_tests && $(DBTF) seed --profile $(PROFILE)
	cd integration_tests && $(DBTF) run --profile $(PROFILE) --select models/ml
	cd integration_tests && $(DBTF) run --profile $(PROFILE) --exclude models/ml --static-analysis=off
	cd integration_tests && $(DBTF) test --profile $(PROFILE) 