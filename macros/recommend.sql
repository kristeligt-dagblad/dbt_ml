{% macro recommend(relation, source, threshold = none) %}
    ml.recommend(
        model {{ relation }},
        (select * from {{ source }})

        {%- if threshold is not none -%}
            , struct({{ threshold }} as threshold)
        {%- endif -%}
    )
{% endmacro %}
