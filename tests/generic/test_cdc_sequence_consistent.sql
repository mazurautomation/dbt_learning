{% test cdc_sequence_consistent(
    model,
    key_column,
    sequence_column,
    payload_columns
) %}

with payloads as (

    select
        {{ adapter.quote(key_column) }} as business_key,
        {{ adapter.quote(sequence_column) }} as sequence_number,

        sha2(
            concat_ws(
                '||',

                {% for column in payload_columns %}

                    coalesce(
                        cast(
                            {{ adapter.quote(column) }}
                            as string
                        ),
                        '<NULL>'
                    )

                    {% if not loop.last %},{% endif %}

                {% endfor %}
            ),
            256
        ) as payload_hash

    from {{ model }}

),

conflicts as (

    select
        business_key,
        sequence_number,
        count(distinct payload_hash) as payload_versions

    from payloads

    group by
        business_key,
        sequence_number

    having count(distinct payload_hash) > 1

)

select *
from conflicts

{% endtest %}