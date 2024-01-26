{% macro forecast(relation, horizon = 30, confidence_level = 0.8) %}
    ml.forecast(
      model {{ relation }},
      struct(
        {{ horizon }} AS horizon,
        {{ confidence_level }} AS confidence_level
      )
    )
{% endmacro %}

