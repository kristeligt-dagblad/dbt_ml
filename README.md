## BigQuery ML models in dbt

Package for dbt that allows users to train, audit and use BigQuery ML models. The package implements a `model` materialization that trains a BigQuery ML model from a select statement and a set of parameters. In addition to the `model` materialization a set of helper macros that assist with model audit and prediction are included.

### Installation

To install the package add the package path to the `packages.yml` file in your dbt project

In order to use the model audit post-hook the following variables have to be set in your `dbt_project.yml` file.

| Variable              | Description                |
| --------------------- | -------------------------- |
| `dbt_ml:audit_schema` | Schema of the audit table. |
| `dbt_ml:audit_table`  | Name of the audit table.   |

You will also need to specify the post-hook in your `dbt_project.yml` file<sup>[1]</sup> as `{{ dbt_ml.model_audit() }}`. Optionally, you can use the `dbt_ml.create_model_audit_table()` macro to create the audit table automatically if it does not exist - for example in an on-run-start hook.

Example config for `dbt_project.yml` below:
```yaml
vars:
  "dbt_ml:audit_schema": "audit"
  "dbt_ml:audit_table": "ml_models"
on-run-start:
  - '{% do adapter.create_schema(api.Relation.create(target.project, "audit")) %}'
  - "{{ dbt_ml.create_model_audit_table() }}"
models:
  <project>:
    ml:
      enabled: true
      schema: ml
      materialized: model
      post-hook: "{{ dbt_ml.model_audit() }}"
```

### Usage

In order to use the `model` materialization, simply create a `.sql` file with a select statement and set the materialization to `model`. Additionaly, specify any BigQuery ML options in the `ml_config` key of the config dictionary.

```sql
# model.sql

{{
    config(
        materialized='model',
        ml_config={
            'model_type': 'logistic_reg',
            'early_stop': true,
            'ls_init_learn_rate': 0.1,
            ...
        }
    )
}}

select * from your_input
```

> Note that the materialization should not be prefixed with `dbt_ml`, since dbt does not support namespaced materializations.

After training your model you can reference it in downstream dbt models using the included `predict` macro.

```sql
# downstream_model.sql

{{
    config(
        materialized='table'
    )
}}

with eval_data as (
    ...
)

select * from {{ dbt_ml.predict(ref('model'), 'eval_data') }}
```

### Documentation

#### `model` _materialization_ ([source](macros/materializations/model.sql))

In order to build (= train) machine learning models in dbt we need to step outside the table and view relations that are shipped with dbt. We create a custom materialization that creates a BigQuery ML model from a select statement and various model selection- and hyperparameters. This brings nearly the full featureset of BigQuery ML models to dbt, and allows us to use the native dbt DAG functionality.

#### `model_audit` _post-hook_ ([source](macros/hooks/model_audit.sql))

To keep track of a model over time the package implements a post-hook that runs after a model is trained. The hook queries model-specific temporary tables in BigQuery for information about the training process and the model itself. The gathered information is logged to an audit table.

#### `predict` _macro_ ([source](macros/predict.sql))

The package implements the `predict` macro that allow users to reference a `model` in ordinary dbt models downstream. The macro makes sure that the model is part of the lineage graph, and handles the boilerplate required when calling the `ml.predict()` function natively in BigQuery.

### Footnotes

[1] The post-hook has to be specified in the `dbt_project.yml` instead of the actual model file because the relation is not available during parsing hence variables like `{{ this }}` are not properly templated.

### References

- [BigQuery ML Syntax and Options](https://cloud.google.com/bigquery-ml/docs/reference/standard-sql/bigqueryml-syntax-create)
- [BigQuery ML Pricing](https://cloud.google.com/bigquery-ml/pricing)
