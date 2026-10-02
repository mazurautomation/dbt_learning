{% macro get_incremental_cdc_soft_delete_sql(arg_dict) %}

    {% set target_relation = arg_dict['target_relation'] %}
    {% set temp_relation = arg_dict['temp_relation'] %}
    {% set unique_key = arg_dict['unique_key'] %}
    {% set incremental_predicates = arg_dict.get('incremental_predicates') or [] %}

    {% if not unique_key %}
        {{ exceptions.raise_compiler_error(
            "cdc_soft_delete incremental strategy requires unique_key"
        ) }}
    {% endif %}

    {% set predicates = [] %}

    {% if unique_key is sequence
          and unique_key is not mapping
          and unique_key is not string %}

        {% for key in unique_key %}
            {% do predicates.append(
                'DBT_INTERNAL_DEST.' ~ adapter.quote(key)
                ~ ' = DBT_INTERNAL_SOURCE.' ~ adapter.quote(key)
            ) %}
        {% endfor %}

    {% else %}

        {% do predicates.append(
            'DBT_INTERNAL_DEST.' ~ adapter.quote(unique_key)
            ~ ' = DBT_INTERNAL_SOURCE.' ~ adapter.quote(unique_key)
        ) %}

    {% endif %}

    {% for predicate in incremental_predicates %}
        {% do predicates.append(predicate) %}
    {% endfor %}

    {% set sql %}

        merge into {{ target_relation }} as DBT_INTERNAL_DEST

        using {{ temp_relation }} as DBT_INTERNAL_SOURCE

        on {{ predicates | join(' and ') }}

        when matched
             and DBT_INTERNAL_SOURCE._cdc_operation = 'D'
             and DBT_INTERNAL_SOURCE._cdc_sequence >
                 coalesce(DBT_INTERNAL_DEST._cdc_sequence, -1)

        then update set
            DBT_INTERNAL_DEST.is_deleted = true,
            DBT_INTERNAL_DEST._cdc_operation =
                DBT_INTERNAL_SOURCE._cdc_operation,
            DBT_INTERNAL_DEST._cdc_sequence =
                DBT_INTERNAL_SOURCE._cdc_sequence,
            DBT_INTERNAL_DEST._loaded_at =
                DBT_INTERNAL_SOURCE._loaded_at

        when matched
             and DBT_INTERNAL_SOURCE._cdc_operation in ('I', 'U')
             and DBT_INTERNAL_SOURCE._cdc_sequence >
                 coalesce(DBT_INTERNAL_DEST._cdc_sequence, -1)

        then update set *

        when not matched
             and DBT_INTERNAL_SOURCE._cdc_operation in ('I', 'U')

        then insert *

    {% endset %}

    {% do return(sql) %}

{% endmacro %}