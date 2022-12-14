{% macro _startup() %}

{% do adapter.create_schema(api.Relation.create(var('dbt_ml:audit_database'), var('dbt_ml:audit_schema'))) %}
{{ dbt_ml.create_model_audit_table() }}

{% endmacro %}
