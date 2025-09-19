{% macro config_meta_get(key, default=none) %}
    {%- if config.get(key) != none -%}
        {{ return(config.get(key)) }}
    {%- elif config.get("meta") != none and (key in config.get("meta", {}).keys()) -%}
        {{ return(config.get("meta").get(key)) }}
    {%- else -%}
        {{ return(default) }}
    {%- endif -%}
{% endmacro %}
