{% macro predict(relation, source, threshold = none) %}
    ml.predict(
        model {{ relation }},
        (select * from {{ source }})

        {%- if threshold is not none -%}
            , struct({{ threshold }} as threshold)
        {%- endif -%}
    )
{% endmacro %}
