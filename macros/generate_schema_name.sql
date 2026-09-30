{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- set environment = var('environment', 'dev') -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif environment == 'prod' and default_schema == 'dbt_prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
