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

If you're using a BQML **matrix_factorization** model, you can use the recommend macro in the same way.
```sql
# downstream_model.sql

with predict_features AS (
    ...
)

select * from {{ dbt_ml.recommend(ref('model'), 'predict_features') }}
```

The ML.DETECT_ANOMALIES function provides anomaly detection for BigQuery ML.

```sql
# detect_anomalies_model.sql

{{
    config(
        materialized='table'
    )
}}

with eval_data as (
    ...
)

select * from {{ dbt_ml.detect_anomalies(ref('model'), 'eval_data', threshold) }}
```

### Tuning hyperparameters
BigQuery ML supports tuning model hyperparameters<sup>[2]</sup>, as does `dbt_ml`. In order to specify which hyperparameters to tune, and which parameterspace to use, one can use the `dbt_ml.hparam_candidates` and `dbt_ml.hparam_range` macros that map to the corresponding BigQuery ML methods.

The following example takes advantage of hyperparameter tuning:
```sql
{{
    config(
        materialized='model',
        ml_config={
            'model_type': 'dnn_classifier',
            'auto_class_weights': true,
            'learn_rate': dbt_ml.hparam_range(0.01, 0.1),
            'early_stop': false,
            'max_iterations': 50,
            'num_trials': 4,
            'optimizer': dbt_ml.hparam_candidates(['adam', 'sgd'])
        }
    )
}}
```
It is worth noting that one must set the `num_trials` parameter to a positive integer, otherwise BigQuery will return an error.

### Overriding the package
If a user wishes to override/shim this package, instead of defining a var named `dbt_ml_dispatch_list`, they should now define [a config](https://next.docs.getdbt.com/reference/project-configs/dispatch-config) in `dbt_project.yml`, for instance:

```yaml
dispatch:
  - macro_namespace: dbt_ml
    search_order: ['my_project', 'dbt_ml']  # enable override
```

### Reservations
Some BigQuery ML models, e.g. Matrix Factorization, cannot be run using the on-demand pricing model. In order to train such models, please set up a flex or regular reservation<sup>[3]</sup>  prior to running the model.

### Footnotes

[1] The post-hook has to be specified in the `dbt_project.yml` instead of the actual model file because the relation is not available during parsing hence variables like `{{ this }}` are not properly templated.

[2] https://cloud.google.com/bigquery-ml/docs/reference/standard-sql/bigqueryml-hyperparameter-tuning

[3] https://cloud.google.com/bigquery/docs/reservations-tasks

### References

- [BigQuery ML Syntax and Options](https://cloud.google.com/bigquery-ml/docs/reference/standard-sql/bigqueryml-syntax-create)
- [BigQuery ML Pricing](https://cloud.google.com/bigquery-ml/pricing)
