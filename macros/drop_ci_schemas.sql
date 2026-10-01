{% macro drop_ci_schemas(pr_number) %}

    {% if execute %}

        {% set base_schema = 'dbt_ci_pr_' ~ pr_number %}

        {% set schemas_to_drop = [
            base_schema,
            base_schema ~ '_silver',
            base_schema ~ '_gold',
            base_schema ~ '_silver_history'
        ] %}

        {% set database_name =
            target.database
            if target.database is defined and target.database
            else target.catalog
        %}

        {% for schema_name in schemas_to_drop %}

            {% set relation = api.Relation.create(
                database=database_name,
                schema=schema_name
            ) %}

            {{ log(
                'Dropping CI schema if it exists: '
                ~ database_name
                ~ '.'
                ~ schema_name,
                info=true
            ) }}

            {% do adapter.drop_schema(relation) %}

        {% endfor %}

    {% endif %}

{% endmacro %}