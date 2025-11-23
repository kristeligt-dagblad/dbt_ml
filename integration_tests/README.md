# dbt_ml Integration Tests

Integration tests for the dbt_ml package focused on validating BigQuery ML functionality.

## What This Tests

### Core Functionality

- **ARIMA_PLUS Model Creation**: Tests time series forecasting model training
- **Logistic Regression**: Tests classification model training
- **Connection to Gemini Model**: Tests creating a basic Gemini model over Vertex conection
- **Model Inference**: Tests `dbt_ml.predict()` and `dbt_ml.forecast()` macros
- **Audit Schema**: Tests model metadata capture and audit table population

### Test Structure

```
integration_tests/
├── dbt_project.yml          # BigQuery ML configuration
├── packages.yml             # Local package reference
├── seeds/                   # Test data
│   ├── timeseries_data.csv  # Sample time series for ARIMA
│   ├── classification_data.csv # Sample data for classification
│   └── text_generation_data.csv # Sample prompts for Gemini
├── models/
│   ├── ml/                  # ML model definitions
│   │   ├── arima_plus_forecast.sql
│   │   ├── logistic_regression.sql
│   │   └── gemini_flash_connection.sql  # Remote Gemini model
│   ├── test_arima_forecast.sql    # Tests forecast macro
│   ├── test_log_regr_prediction.sql  # Tests predict macro
│   └── test_gemini_generation.sql  # Tests text generation
└── tests/                   # Data quality tests
    ├── test_arima_model_exists.sql
    ├── test_audit_table_populated.sql
    ├── test_forecast_output.sql
    └── test_gemini_output.sql
```

## Running Tests

### Prerequisites

1. **BigQuery Project**: You need a GCP project with BigQuery ML enabled
2. **dbt Profile**: Set up a BigQuery profile named `integration_tests`
3. **Vertex AI Connection**: For remote model tests, create a Vertex AI connection named `vertexai-connection` in the `eu` region. Make sure to also enable the Vertex AI API. Additionally, grant the Vertex AI user role to your authentication method of choice. See [here](https://docs.cloud.google.com/bigquery/docs/create-cloud-resource-connection) and [here](https://cloud.google.com/bigquery/docs/generate-text-tutorial#grant-permissions) for reference.

Example `profiles.yml`:

```yaml
integration_tests:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: your-gcp-project-id
      dataset: dbt_ml_tests
      threads: 4
      location: EU
```

### Running the Tests

To run all integration tests with one command, use the Makefile target provided in the project root, testing either with `dbt-core` or `dbt-fusion`:

```bash
make test[-fusion]
```

This will install dependencies, seed test data, train ML models, run inference, and execute all tests.

_Note: When running with dbt fusion, static-analysis must be turned off due to a known issue; see [here](https://github.com/dbt-labs/dbt-fusion/issues/742) for details._

## What Gets Tested

### ML Model Training

- **ARIMA_PLUS**: Time series forecasting with auto-configuration
- **Logistic Regression**: Binary classification with class weights
- **Gemini Remote Model**: Remote model using Vertex AI connection for text generation

### ML Inference

- **Forecasting**: Using `dbt_ml.forecast()` for 7-day ahead prediction
- **Prediction**: Using `dbt_ml.predict()` for classification
- **Text Generation**: Using `ML.GENERATE_TEXT` with Gemini remote model

### Audit Functionality

- **Audit Table Creation**: Validates audit schema setup
- **Model Metadata**: Checks training info, feature info captured
- **Post-hook Execution**: Ensures audit post-hook works

### Data Quality

- **Model Existence**: Verifies models created in BigQuery
- **Output Structure**: Validates prediction/forecast output columns
- **Audit Population**: Ensures audit records created
