{% macro mark_cdc_batch_processed(
    batch_id,
    run_id='manual',
    pipeline_name='pharmacy_cdc'
) %}

    {% set sql %}

        merge into {{ target.catalog }}.ops.cdc_batch_control as target

        using (

            select
                '{{ pipeline_name }}' as pipeline_name,
                cast({{ batch_id }} as bigint)
                    as last_successful_batch_id,
                current_timestamp() as updated_at,
                '{{ run_id }}' as run_id

        ) as source

        on target.pipeline_name = source.pipeline_name

        when matched
             and source.last_successful_batch_id
                 > target.last_successful_batch_id

        then update set *

        when not matched
        then insert *

    {% endset %}

    {% if execute %}

        {% do run_query(sql) %}

        {{ log(
            'Marked CDC batch '
            ~ batch_id
            ~ ' as successfully processed.',
            info=true
        ) }}

    {% endif %}

{% endmacro %}