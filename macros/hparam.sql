{% macro hparam_range(min_, max_) %}
    {{ return(['hparam_range', min_, max_]) }}
{% endmacro %}

{% macro hparam_candidates(candidates) %}
    {{ return(['hparam_candidates', candidates]) }}
{% endmacro %}