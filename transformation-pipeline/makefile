DBT_PATH := transformation_pipeline

# Define the target for running dbt
.PHONY: dev

dev:
	@echo "Running dbt..."
	@dbt run --project-dir $(DBT_PATH) --target dev