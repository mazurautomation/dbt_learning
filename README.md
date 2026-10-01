# Pharmacy Analytics — dbt + Databricks Medallion Project

Practical analytics engineering project built with dbt Core and Databricks. The repository demonstrates a production-style Medallion Architecture, incremental Delta Lake processing, data quality tests, Databricks Asset Bundles, and GitHub Actions CI/CD.

The project uses synthetic online-pharmacy/e-commerce data only, not real data.

## Architecture

```text
Source systems
      |
      | ADF ingestion in production
      | simulated by setup SQL in this lab
      v
+----------------------+
| BRONZE               |
| bronze.*             |
| raw Delta tables     |
| ingestion-owned      |
+----------+-----------+
           |
           | dbt source()
           v
+----------------------------+
| SILVER                     |
| cleaned / typed / DQ       |
| DEV:  dbt_pawel_silver.*   |
| PROD: silver.*             |
+-------------+--------------+
              |
              | dbt ref()
              v
+----------------------------+
| GOLD                       |
| dimensions / facts / KPIs  |
| DEV:  dbt_pawel_gold.*     |
| PROD: gold.*               |
+----------------------------+
```

The repository folders remain `staging`, `intermediate`, and `marts` because they describe the role of dbt code. Bronze/Silver/Gold describe the physical data architecture.

## Production orchestration

```text
Azure Data Factory
        |
        | ingestion / orchestration
        v
Databricks Bronze
        |
        | Databricks Job Activity
        v
Databricks Job
        |
        | native dbt task
        v
dbt build
        |
        +--> Silver
        +--> Gold
        +--> tests
```

Responsibilities:

- **ADF** — orchestration and ingestion.
- **Databricks** — compute, Delta Lake, Unity Catalog, SQL Warehouse, Jobs.
- **dbt** — transformation DAG, incremental models, tests, documentation and lineage.
- **GitHub Actions** — CI/CD for Databricks Asset Bundles.

ADF should not reproduce individual dbt model dependencies as separate activities. Dependencies inside the transformation layer are owned by dbt through `ref()`.

## Physical objects

### Bronze — outside dbt ownership

- `bronze.customers`
- `bronze.products`
- `bronze.orders`
- `bronze.order_items`
- `bronze.payments`

### Silver — built by dbt

- `stg_customers`
- `stg_products`
- `stg_orders`
- `stg_order_items`
- `stg_payments`

`stg_orders`, `stg_order_items`, and `stg_payments` are incremental Delta models using `MERGE`.

Keys:

- `stg_orders` -> `order_id`
- `stg_order_items` -> `order_item_id`
- `stg_payments` -> `payment_id`

The models use `_loaded_at` as the ingestion watermark and a configurable lookback window.

Default:

```yaml
vars:
  incremental_lookback_hours: 24
```

### Intermediate

Intermediate models are materialized as `ephemeral`:

- `int_order_items_aggregated`
- `int_payments_aggregated`
- `int_orders_enriched`

### Gold — built by dbt

- `dim_customers`
- `dim_products`
- `fct_orders`
- `fct_daily_sales`

`fct_orders` is incremental and uses Databricks Delta `MERGE`.

### History

Customer history is stored as an SCD Type 2 dbt snapshot:

- DEV: `dbt_pawel_silver_history.customers_snapshot`
- PROD: `silver_history.customers_snapshot`

## DEV vs PROD isolation

DEV:

```text
dbt_pawel_silver
dbt_pawel_gold
dbt_pawel_silver_history
```

PROD:

```text
silver
gold
silver_history
```

`macros/generate_schema_name.sql` prevents local development from writing into shared production schemas.

## dbt features covered

- `source()`
- `ref()`
- dbt DAG
- `table`
- `ephemeral`
- `incremental`
- Databricks Delta `MERGE`
- `unique_key`
- `is_incremental()`
- incremental lookback
- Jinja macros
- project variables
- generic data tests
- singular SQL tests
- `relationships`
- `accepted_values`
- `not_null`
- `unique`
- `dbt_utils`
- snapshots / SCD Type 2
- source freshness
- documentation and lineage
- DEV / PROD isolation
- Databricks Jobs
- Databricks Asset Bundles
- GitHub Actions CI/CD
- dbt Slim CI

## Data quality

Examples:

```text
not_null
unique
relationships
accepted_values
dbt_utils.expression_is_true
```

Singular tests implement business rules. Zero returned rows means PASS; one or more returned rows means FAIL.

Because production uses `dbt build`, a failed data test can fail the Databricks Job and propagate failure to an orchestrator such as ADF.

## dbt packages

Packages are declared in:

```text
packages.yml
```

Install locally:

```powershell
dbt deps
```

`dbt_packages/` is generated locally and is not committed.

## Local development

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
pip install dbt-databricks

dbt deps
dbt debug
dbt clean
dbt parse
dbt build
```

Do not run a project-wide `dbt test` before the first build in a new environment. `dbt build` creates models and runs tests in DAG order.

## Initial Bronze setup

From scratch:

```text
setup/create_bronze_data.sql
```

Migration from the old tutorial schema:

```text
setup/migrate_existing_raw_to_bronze.sql
```

Cleanup of legacy schemas:

```text
setup/cleanup_legacy_schemas.sql
```

## Incremental batch exercise

Simulate ingestion:

```text
setup/simulate_adf_daily_batch.sql
```

Run affected Silver models:

```powershell
dbt build --select stg_orders stg_order_items stg_payments
```

Propagate to Gold:

```powershell
dbt build --select fct_orders+
```

Verify:

```text
setup/verify_incremental_batch.sql
```

Inspect generated SQL:

```powershell
dbt compile --select stg_orders
```

Also inspect:

- `logs/dbt.log`
- Databricks SQL Warehouse Query History

## Useful dbt commands

```powershell
dbt build --selector silver
dbt build --selector gold
dbt build --select fct_orders+
dbt compile --select fct_orders
dbt snapshot
dbt docs generate
dbt docs serve
dbt source freshness
```

## Databricks Asset Bundles

Jobs are managed as code.

Main files:

```text
databricks.yml
resources/pharmacy_analytics_dbt.job.yml
```

DEV:

```powershell
databricks bundle validate -t dev -p dbt-learning
databricks bundle plan -t dev -p dbt-learning
databricks bundle deploy -t dev -p dbt-learning
databricks bundle run -t dev -p dbt-learning pharmacy_analytics_dbt_job
```

PROD:

```powershell
databricks bundle validate -t prod -p dbt-learning
databricks bundle plan -t prod -p dbt-learning
databricks bundle deploy -t prod -p dbt-learning
databricks bundle run -t prod -p dbt-learning pharmacy_analytics_dbt_job
databricks bundle summary -t prod -p dbt-learning
```

## Production dbt Job

The Databricks dbt task runs:

```text
dbt deps
dbt build --vars '{"environment":"prod"}'
```

For PROD:

```text
Warehouse schema = dbt_prod
environment = prod
```

The custom schema macro maps output to:

```text
silver
gold
silver_history
```

## Git workflow

```text
main
  |
  +--> feature/*
          |
          +--> commit
          +--> push
          +--> Pull Request
                    |
                    v
                 PR CI
                    |
                    v
                  merge
                    |
                    v
                  main
                    |
                    v
             PROD deployment
```

Typical commands:

```powershell
git checkout main
git pull
git checkout -b feature/my-change

git add .
git commit -m "Describe change"
git push -u origin feature/my-change
```

## GitHub Actions

### PROD CD

Push to `main`:

```text
checkout
   |
install Databricks CLI
   |
bundle validate -t prod
   |
bundle plan -t prod
   |
bundle deploy -t prod
   |
bundle summary -t prod
```

GitHub Actions deploys code/configuration. Production data execution remains the responsibility of the Databricks Job/orchestrator.

### PR CI / Slim CI

Pull Requests to `main` use dbt state comparison against the manifest from the latest successful PROD dbt Job.

```text
latest successful PROD dbt run
          |
          v
archived manifest.json
          |
          v
GitHub PR workflow
          |
          | state:modified+
          v
changed models + downstream DAG
          |
          | --defer --favor-state
          v
unchanged parents resolve to PROD
```

Core command:

```bash
dbt build   --target ci   --select "state:modified+"   --state prod_state   --defer   --favor-state   --vars '{"environment":"dev"}'
```

Each PR uses an isolated base schema such as:

```text
dbt_ci_pr_<PR_NUMBER>
```

The PROD manifest is downloaded dynamically from Databricks Job archived dbt artifacts and is not committed to Git.

## Authentication

Local development uses Databricks CLI OAuth.

The lab GitHub Actions setup uses a Databricks PAT stored as a GitHub Environment secret.

For real production:

```text
GitHub Actions
      |
      | OIDC / workload identity federation
      v
Databricks service principal
```

## ADF integration

Intended production flow:

```text
ADF ingestion
      |
      v
Bronze ready
      |
      v
ADF Databricks Job Activity
      |
      v
Databricks Job created by Asset Bundle
      |
      v
dbt build
```

See:

```text
docs/production_orchestration.md
docs/databricks_job_and_adf.md
adf/README.md
adf/databricks_job_activity.template.json
```

## Repository structure

```text
.
├── .github/
│   └── workflows/
│       ├── deploy-databricks.yml
│       └── pr-ci.yml
├── adf/
├── analyses/
├── docs/
├── macros/
│   ├── generate_schema_name.sql
│   ├── incremental_watermark_filter.sql
│   └── normalize_status.sql
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── resources/
│   └── pharmacy_analytics_dbt.job.yml
├── seeds/
├── setup/
├── snapshots/
├── tests/
├── databricks.yml
├── dbt_project.yml
├── packages.yml
├── selectors.yml
└── README.md
```

## Security

Do not commit:

- `.venv/`
- `profiles.yml`
- `.env`
- Databricks tokens
- GitHub tokens
- `target/`
- `logs/`
- `dbt_packages/`

CI/CD secrets belong in GitHub Secrets / Environments or should be replaced by workload identity federation in production.
