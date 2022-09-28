{% macro detect_anomalies(relation, source, threshold = 0.95) %}
    ml.detect_anomalies(
        model {{ relation }},
        struct({{ threshold }} as anomaly_prob_threshold),
        (select * from {{ source }})
    )
{% endmacro %}