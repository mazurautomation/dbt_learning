{% macro validate_cdc_batch_id(batch_id) %}

    {% if batch_id | int <= 0 %}

        {{ exceptions.raise_compiler_error(
            "cdc_batch_id must be a positive integer. "
            ~ "The orchestrator must explicitly provide the ingestion batch ID."
        ) }}

    {% endif %}

{% endmacro %}