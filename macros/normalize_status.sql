{% macro normalize_status(column_name) -%}
    lower(trim({{ column_name }}))
{%- endmacro %}
