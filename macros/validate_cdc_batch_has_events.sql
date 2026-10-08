{% macro validate_cdc_batch_has_events(batch_id) %}

    {% if execute %}

        {% set sql %}

            select sum(event_count) as total_events

            from (

                select count(*) as event_count
                from {{ source('pharmacy_bronze', 'orders_cdc') }}
                where cast(_ingest_batch_id as bigint)
                    = cast({{ batch_id }} as bigint)

                union all

                select count(*) as event_count
                from {{ source('pharmacy_bronze', 'order_items_cdc') }}
                where cast(_ingest_batch_id as bigint)
                    = cast({{ batch_id }} as bigint)

                union all

                select count(*) as event_count
                from {{ source('pharmacy_bronze', 'payments_cdc') }}
                where cast(_ingest_batch_id as bigint)
                    = cast({{ batch_id }} as bigint)

            )

        {% endset %}

        {% set result = run_query(sql) %}

        {% set total_events =
            result.columns[0].values()[0] | int
        %}

        {% if total_events <= 0 %}

            {{ exceptions.raise_compiler_error(
                "CDC batch "
                ~ batch_id
                ~ " does not contain any Bronze events. "
                ~ "Watermark advancement has been blocked."
            ) }}

        {% endif %}

        {% do log(
            "CDC batch "
            ~ batch_id
            ~ " contains "
            ~ total_events
            ~ " Bronze events.",
            info=true
        ) %}

    {% endif %}

{% endmacro %}