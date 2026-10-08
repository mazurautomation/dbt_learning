{% macro mark_cdc_batch_processed(
    batch_id,
    run_id='unknown',
    pipeline_name='pharmacy_cdc'
) %}

    {% set environment =
        var('environment', 'dev')
    %}

    {% set sql %}

        merge into {{ source(
            'pipeline_control',
            'cdc_batch_control'
        ) }} as target

        using (

            select
                '{{ environment }}' as environment,
                '{{ pipeline_name }}' as pipeline_name,
                cast({{ batch_id }} as bigint) as batch_id,
                '{{ run_id }}' as run_id

        ) as source

        on target.environment = source.environment
        and target.pipeline_name = source.pipeline_name

        when matched
          and source.batch_id > target.last_successful_batch_id
        then update set

            last_successful_batch_id = source.batch_id,
            updated_at = current_timestamp(),
            run_id = source.run_id

        when not matched
        then insert (
            environment,
            pipeline_name,
            last_successful_batch_id,
            updated_at,
            run_id
        )

        values (
            source.environment,
            source.pipeline_name,
            source.batch_id,
            current_timestamp(),
            source.run_id
        )

    {% endset %}

    {% do run_query(sql) %}

{% endmacro %}