{% macro log_dbt_run_results(results) %}

    {% if execute %}

        {% set environment = var('environment', 'dev') %}
        {% set orchestrator_run_id = var('orchestrator_run_id', 'local') %}
        {% set cdc_batch_id = var('cdc_batch_id', none) %}

        {% set create_sql %}

            create table if not exists {{ target.catalog }}.ops.dbt_run_audit (

                dbt_invocation_id string,
                orchestrator_run_id string,
                environment string,
                cdc_batch_id bigint,

                node_unique_id string,
                node_name string,
                resource_type string,
                status string,

                invocation_started_at timestamp,
                recorded_at timestamp,

                execution_time_seconds double,
                rows_affected bigint,
                query_id string,

                message string

            )
            using delta

        {% endset %}

        {% do run_query(create_sql) %}


        {% for result in results %}

            {% set node_unique_id =
                result.node.unique_id | replace("'", "''")
            %}

            {% set node_name =
                result.node.name | replace("'", "''")
            %}

            {% set resource_type =
                result.node.resource_type | string | replace("'", "''")
            %}

            {% set status =
                result.status | string | replace("'", "''")
            %}

            {% set message =
                (result.message or '') | string | replace("'", "''")
            %}

            {% set rows_affected =
                result.adapter_response.get('rows_affected')
                if result.adapter_response
                else none
            %}

            {% set query_id =
                result.adapter_response.get('query_id')
                if result.adapter_response
                else none
            %}

            {% set insert_sql %}

                insert into {{ target.catalog }}.ops.dbt_run_audit
                (
                    dbt_invocation_id,
                    orchestrator_run_id,
                    environment,
                    cdc_batch_id,
                    node_unique_id,
                    node_name,
                    resource_type,
                    status,
                    invocation_started_at,
                    recorded_at,
                    execution_time_seconds,
                    rows_affected,
                    query_id,
                    message
                )

                values
                (
                    '{{ invocation_id }}',
                    '{{ orchestrator_run_id }}',
                    '{{ environment }}',

                    {% if cdc_batch_id is not none %}
                        {{ cdc_batch_id }}
                    {% else %}
                        null
                    {% endif %},

                    '{{ node_unique_id }}',
                    '{{ node_name }}',
                    '{{ resource_type }}',
                    '{{ status }}',

                    cast(
                        '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S.%f") }}'
                        as timestamp
                    ),

                    current_timestamp(),

                    {{ result.execution_time or 0 }},

                    {% if rows_affected is not none %}
                        {{ rows_affected }}
                    {% else %}
                        null
                    {% endif %},

                    {% if query_id is not none %}
                        '{{ query_id }}'
                    {% else %}
                        null
                    {% endif %},

                    '{{ message }}'
                )

            {% endset %}

            {% do run_query(insert_sql) %}

        {% endfor %}

    {% endif %}

{% endmacro %}