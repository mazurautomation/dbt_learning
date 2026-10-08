{% macro cdc_batch_filter(
    batch_column='_ingest_batch_id',
    pipeline_name='pharmacy_cdc'
) %}

    {% if is_incremental() %}

        {% set current_batch_id =
            var('cdc_batch_id', 9223372036854775807)
        %}

        {% set environment =
            var('environment', 'dev')
        %}

        where cast({{ batch_column }} as bigint) > (

            select
                coalesce(
                    max(last_successful_batch_id),
                    0
                )

            from {{ source(
                'pipeline_control',
                'cdc_batch_control'
            ) }}

            where pipeline_name = '{{ pipeline_name }}'
              and environment = '{{ environment }}'

        )

        and cast({{ batch_column }} as bigint)
            <= {{ current_batch_id }}

    {% endif %}

{% endmacro %}