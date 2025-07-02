{% macro drop_model(relation) %}
    {{
        adapter.dispatch(
            macro_name='drop_model',
            macro_namespace='dbt_ml'
        )
        (relation)
    }}
{% endmacro %}

{% macro default__drop_model(relation) %}
    {{ exceptions.raise_compiler_error("Dropping ML models is not implemented for the default adapter") }}
{% endmacro %}

{% macro bigquery__drop_model(relation) %}
    {% call statement('drop_relation') -%}
        drop {{ relation.type | default('model') }} if exists {{ relation }}
    {%- endcall %}
{% endmacro %}

{% macro model_options(ml_config, labels) %}

    {% set options -%}
        options(
            {%- for opt_key, opt_val in ml_config.items() -%}
                {%- if opt_val is sequence and (opt_val | first) is string and (opt_val | first).startswith('hparam_') -%}
                    {{ opt_key }}={{ opt_val[0] }}({{ opt_val[1:] | join(', ') }})
                {%- elif opt_key == 'class_weights' -%}
                    {{ opt_key }}={{ opt_val }}
                {%- else -%}
                    {{ opt_key }}={{ (opt_val | tojson) if opt_val is string else opt_val }}
                {%- endif -%}
                {{ ',' if not loop.last }}
            {%- endfor -%}
        )
    {%- endset %}

    {%- do return(options) -%}
{%- endmacro -%}

{% macro create_model_as(relation, sql) -%}
    {{
        adapter.dispatch(
            macro_name='create_model_as',
            macro_namespace='dbt_ml'
        )
        (relation, sql)
    }}
{%- endmacro %}

{% macro default__create_model_as(relation, sql) %}
    {{ exceptions.raise_compiler_error("ML model creation is not implemented for the default adapter") }}
{% endmacro %}

{% macro bigquery__create_model_as(relation, sql) %}
    {%- set ml_config = config.get('ml_config', {}) -%}
    {%- set raw_labels = config.get('labels', {}) -%}
    {%- set sql_header = config.get('sql_header', none) -%}
    {%- set prevent_overwrite = config.get('prevent_overwrite', False) -%}

    {{ sql_header if sql_header is not none }}

    create
    {% if prevent_overwrite %}
    model if not exists
    {% else %}
    or replace model
    {% endif %}

    {{ relation }}

    {% if ml_config.get('connection_name') %}
        remote with connection `{{ ml_config.pop('connection_name') }}`
    {% endif %}

    {{ dbt_ml.model_options(
        ml_config=ml_config,
        labels=raw_labels
    ) }}

    {%- if sql -%}
        as (
            {{ sql }}
        );
    {%- endif -%}
{% endmacro %}

{% materialization model, adapter='bigquery' -%}
    {%- set identifier = model['alias'] -%}
    {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}    
    {%- set target_relation = api.Relation.create(database=database, schema=schema, identifier=identifier) -%}

    {{ run_hooks(pre_hooks) }}

    {% call statement('main') -%}
        {{ dbt_ml.create_model_as(target_relation, sql) }}
    {% endcall -%}

    {{ run_hooks(post_hooks) }}

    {{ return({'relations': [target_relation]}) }}
{% endmaterialization %}
