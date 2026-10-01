{% macro incremental_watermark_filter(column_name) %}

    {% if is_incremental() %}

        where cast({{ column_name }} as timestamp) >= (
            select coalesce(
                timestampadd(
                    HOUR,
                    -{{ var('incremental_lookback_hours', 24) }},
                    max(cast({{ column_name }} as timestamp))
                ),
                cast('1900-01-01 00:00:00' as timestamp)
            )
            from {{ this }}
        )

    {% endif %}

{% endmacro %}