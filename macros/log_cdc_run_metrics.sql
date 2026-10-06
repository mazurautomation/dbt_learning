{% macro log_cdc_run_metrics(results) %}

    {% if execute and var('enable_observability', true) %}

        {% set environment = var('environment', 'dev') %}
        {% set orchestrator_run_id = var('orchestrator_run_id', 'local') %}
        {% set cdc_batch_id = var('cdc_batch_id', none) %}

        {% if cdc_batch_id is not none %}

            {% set ns = namespace(run_status='SUCCESS') %}

            {% for result in results %}
                {% set result_status = result.status | string | lower %}

                {% if result_status in ['error', 'fail'] %}
                    {% set ns.run_status = 'FAILED' %}
                {% endif %}
            {% endfor %}

            {% set create_sql %}

                create table if not exists
                    {{ target.catalog }}.ops.cdc_run_metrics
                (
                    dbt_invocation_id string,
                    orchestrator_run_id string,
                    environment string,

                    requested_batch_id bigint,
                    watermark_before_run bigint,

                    run_status string,

                    orders_input_events bigint,
                    order_items_input_events bigint,
                    payments_input_events bigint,

                    insert_events bigint,
                    update_events bigint,
                    delete_events bigint,

                    total_input_events bigint,

                    recorded_at timestamp
                )
                using delta

            {% endset %}

            {% do run_query(create_sql) %}


            {% set metrics_sql %}

                insert into {{ target.catalog }}.ops.cdc_run_metrics

                with control as (

                    select
                        coalesce(
                            max(last_successful_batch_id),
                            0
                        ) as watermark_before_run

                    from {{ source(
                        'pipeline_control',
                        'cdc_batch_control'
                    ) }}

                    where pipeline_name = 'pharmacy_cdc'

                ),

                events as (

                    select
                        'orders' as entity_name,
                        _cdc_operation,
                        _ingest_batch_id
                    from {{ source(
                        'pharmacy_bronze',
                        'orders_cdc'
                    ) }}

                    union all

                    select
                        'order_items',
                        _cdc_operation,
                        _ingest_batch_id
                    from {{ source(
                        'pharmacy_bronze',
                        'order_items_cdc'
                    ) }}

                    union all

                    select
                        'payments',
                        _cdc_operation,
                        _ingest_batch_id
                    from {{ source(
                        'pharmacy_bronze',
                        'payments_cdc'
                    ) }}

                ),

                metrics as (

                    select

                        count_if(
                            entity_name = 'orders'
                        ) as orders_input_events,

                        count_if(
                            entity_name = 'order_items'
                        ) as order_items_input_events,

                        count_if(
                            entity_name = 'payments'
                        ) as payments_input_events,

                        count_if(
                            _cdc_operation = 'I'
                        ) as insert_events,

                        count_if(
                            _cdc_operation = 'U'
                        ) as update_events,

                        count_if(
                            _cdc_operation = 'D'
                        ) as delete_events,

                        count(*) as total_input_events

                    from events
                    cross join control

                    where cast(_ingest_batch_id as bigint)
                        > control.watermark_before_run

                      and cast(_ingest_batch_id as bigint)
                        <= {{ cdc_batch_id }}

                )

                select
                    '{{ invocation_id }}',
                    '{{ orchestrator_run_id }}',
                    '{{ environment }}',

                    {{ cdc_batch_id }},
                    control.watermark_before_run,

                    '{{ ns.run_status }}',

                    metrics.orders_input_events,
                    metrics.order_items_input_events,
                    metrics.payments_input_events,

                    metrics.insert_events,
                    metrics.update_events,
                    metrics.delete_events,

                    metrics.total_input_events,

                    current_timestamp()

                from control
                cross join metrics

            {% endset %}

            {% do run_query(metrics_sql) %}

        {% endif %}

    {% endif %}

{% endmacro %}