{% set _audit_table_columns = {
    'model': 'string',
    'schema': 'string',
    'created_at': dbt_utils.type_timestamp(),
    'training_info': 'array<struct<training_run int64, iteration int64, loss float64, eval_loss float64, learning_rate float64, duration_ms int64, cluster_info array<struct<centroid_id int64, cluster_radius float64, cluster_size int64>>>>',
    'feature_info': 'array<struct<input string, min float64, max float64, mean float64, median float64, stddev float64, category_count int64, null_count int64>>',
    'weights': 'array<struct<processed_input string, weight float64, category_weights array<struct<category string, weight float64>>>>',
} %}

{% set _audit_insert_templates = {
    'default': {
        'training_info': [
            'training_run',
            'iteration',
            'loss',
            'eval_loss',
            'learning_rate',
            'duration_ms',
            'array(select as struct null as centroid_id, cast(null as float64) as cluster_radius, null as cluster_size)'
        ],
        'feature_info': ['*'],
        'weights': ['*']
    },
    'kmeans': {
        'training_info': [
            'training_run',
            'iteration',
            'loss',
            'cast(null as float64) as eval_loss',
            'cast(null as float64) as learning_rate',
            'duration_ms',
            'cluster_info'
        ],
        'feature_info': ['*']
    }
} %}

{% macro _get_audit_info_cols(model_type, info_type) %}

    {% set cols = none %}
    {% if model_type in _audit_insert_templates.keys() %}
        {% if info_type in _audit_insert_templates[model_type].keys() %}
            {% set cols = _audit_insert_templates[model_type][info_type] %}
        {% endif %}
    {% endif %}

    {% if cols is none %}
        {% set cols = _audit_insert_templates['default'][info_type] %}
    {% endif %}

    {% do return(cols) %}

{% endmacro %}

{% macro model_audit() %}

    {% set model_type = config.get('ml_config')['model_type'] %}
    {% set model_type_repr = _audit_insert_templates.get(model_type, 'default') %}

    {% set info_types = ['training_info', 'feature_info', 'weights'] %}

    insert `{{ target.database }}.{{ var('dbt_ml:audit_schema') }}.{{ var('dbt_ml:audit_table') }}`
    (model, schema, created_at, {{ info_types | join(', ') }})

    select
        '{{ this.table }}' as model,
        '{{ this.schema }}' as schema,
        current_timestamp as created_at,

        {% for info_type in info_types %}
            {% if info_type not in _audit_insert_templates[model_type_repr] %}
                cast(null as {{ _audit_table_columns[info_type] }}) as {{ info_type }}
            {% else %}
                array(
                    select as struct {{ dbt_ml._get_audit_info_cols(model_type, info_type) | join(', ') }}
                    from ml.{{ info_type }}(model {{ this }})
                ) as {{ info_type }}
            {% endif %}
            {% if not loop.last %},{% endif %}
        {% endfor %}

{% endmacro %}

{% macro create_model_audit_table() %}
    {%- set audit_table =
        api.Relation.create(
            database=target.database,
            schema=var('dbt_ml:audit_schema'),
            identifier=var('dbt_ml:audit_table'),
            type='table'
        ) -%}

    {% set audit_table_exists = adapter.get_relation(audit_table.database, audit_table.schema, audit_table.name) %}

    {% if not audit_table_exists -%}
        create table if not exists {{ audit_table }}
        (
        {% for column, type in _audit_table_columns.items() %}
            {{ column }} {{ type }}{% if not loop.last %},{% endif %}
        {% endfor %}
        )
    {%- endif -%}
{% endmacro %}
