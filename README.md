# Pharmacy Analytics — dbt + Databricks Medallion Project

Practical analytics engineering project built with dbt Core and Databricks. It demonstrates a production-style Medallion Architecture, append-only CDC ingestion, incremental Delta Lake processing, data quality controls, model contracts, observability, Databricks Asset Bundles, GitHub Actions CI/CD, Terraform infrastructure ownership, and a production OIDC reference.

The project uses synthetic online-pharmacy / e-commerce data only.

## Architecture

```text
Source systems
      |
      | ADF ingestion in production
      | simulated by setup SQL in this lab
      v
+----------------------------+
| BRONZE                     |
| workspace.bronze.*         |
| append-only CDC / raw data |
| ingestion-owned            |
+-------------+--------------+
              |
              | dbt source()
              v
+----------------------------+
| SILVER                     |
| current-state models       |
| DEV:  dbt_pawel_silver.*   |
| PROD: silver.*             |
+-------------+--------------+
              |
              | dbt ref()
              v
+----------------------------+
| INTERMEDIATE               |
| business enrichment        |
| ephemeral                  |
+-------------+--------------+
              |
              v
+----------------------------+
| GOLD                       |
| dimensions / facts / KPIs  |
| DEV:  dbt_pawel_gold.*     |
| PROD: gold.*               |
+----------------------------+
```

Repository folders remain `staging`, `intermediate`, and `marts` because they describe the role of dbt code. Bronze/Silver/Gold describe the physical data architecture.

## Production orchestration

```text
Azure Data Factory
      |
      | ingest complete CDC batch
      v
Databricks Bronze
      |
      | cdc_batch_id = N
      v
Databricks Job
      |
      +--> validate_cdc_batch_id
      |
      +--> validate_cdc_batch_has_events
      |
      +--> source freshness gate
      |
      v
dbt build
      |
      +--> Silver
      +--> Intermediate
      +--> Gold
      +--> tests
      +--> observability hooks
      |
      v
mark_cdc_batch_processed
      |
      v
ops.cdc_batch_control
```

Responsibilities:

- **ADF** — ingestion and orchestration. It must finish the whole ingestion batch before starting the Databricks Job.
- **Databricks** — compute, Delta Lake, Unity Catalog, SQL Warehouse and Jobs.
- **dbt** — transformation DAG, CDC processing, models, tests, contracts, documentation and lineage.
- **GitHub Actions** — pull request CI and Asset Bundle deployment.
- **Terraform** — infrastructure and permissions ownership.
- **Databricks Asset Bundles** — Databricks Job definitions and deployment.

ADF does not reproduce individual dbt model dependencies. Dependencies inside the transformation layer are owned by dbt through `ref()`.

## Physical objects

### Bronze — outside dbt ownership

Static/raw sources:

- `workspace.bronze.customers`
- `workspace.bronze.products`

Append-only CDC sources:

- `workspace.bronze.orders_cdc`
- `workspace.bronze.order_items_cdc`
- `workspace.bronze.payments_cdc`

CDC event metadata:

```text
_cdc_operation
_cdc_sequence
_ingest_batch_id
_loaded_at
```

Meaning:

- `_cdc_operation` — `I`, `U` or `D`.
- `_cdc_sequence` — business event ordering for a record/key.
- `_ingest_batch_id` — ingestion batch ordering used by pipeline high-water marks.
- `_loaded_at` — ingestion audit timestamp and source-freshness signal.

`_loaded_at` is intentionally **not** used as the incremental watermark.

### Pipeline control

```text
workspace.ops.cdc_batch_control
```

The logical key is:

```text
(environment, pipeline_name)
```

Example:

```text
dev  | pharmacy_cdc | 5
prod | pharmacy_cdc | 4
```

DEV and PROD therefore own independent watermarks.

### Silver — built by dbt

- `stg_customers`
- `stg_products`
- `stg_orders`
- `stg_order_items`
- `stg_payments`

The CDC staging models are incremental Delta models using custom merge logic.

They provide:

- current state per business key,
- sequence-aware CDC handling,
- stale-event protection,
- replay tolerance,
- soft-delete tombstones,
- ingestion batch propagation.

Keys:

- `stg_orders` → `order_id`
- `stg_order_items` → `order_item_id`
- `stg_payments` → `payment_id`

### Intermediate

Ephemeral models:

- `int_order_items_aggregated`
- `int_payments_aggregated`
- `int_orders_enriched`

### Gold — built by dbt

- `dim_customers`
- `dim_products`
- `fct_orders`
- `fct_daily_sales`

`fct_orders` is incremental and uses hard-delete semantics for records deleted in CDC.

The model has an enforced dbt contract and explicit schema-evolution protection.

Important fields include:

```text
order_id
customer_id
order_status
ordered_at
item_quantity
order_amount
paid_amount
currency_code
is_deleted
record_updated_at
_ingest_batch_id
```

`currency_code` is currently `PLN`.

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

CDC control is also isolated logically by the `environment` column in `ops.cdc_batch_control`.

## CDC batch processing

Incremental models process only events satisfying:

```text
last_successful_batch_id < _ingest_batch_id <= cdc_batch_id
```

The lower bound is read from `ops.cdc_batch_control` using both `environment` and `pipeline_name`.

The upper bound is supplied by the orchestrator as `cdc_batch_id`.

A production run must explicitly pass a positive batch ID.

Example:

```powershell
databricks bundle run `
  -t dev `
  -p dbt-learning `
  --params cdc_batch_id=5 `
  pharmacy_analytics_dbt_job
```

The Job blocks execution when:

- `cdc_batch_id <= 0`,
- the requested batch contains zero CDC events,
- source freshness reaches its error threshold.

The watermark is advanced only after a successful `dbt_build`.

### Production batch invariant

A batch ID is immutable once processed.

Correct:

```text
ADF Copy orders N --------\
ADF Copy order_items N ----+--> all complete --> Databricks Job(cdc_batch_id=N)
ADF Copy payments N -------/
```

Late-arriving ingestion must receive a new `_ingest_batch_id`.

## Source freshness

`orders_cdc` is configured with:

```yaml
warn_after: 24 hours
error_after: 72 hours
loaded_at_field: _loaded_at
```

The Databricks Job executes source freshness before transformations:

```text
source_freshness
      |
      v
dbt_build
      |
      v
mark_cdc_batch_processed
```

If freshness fails, downstream tasks are skipped and the watermark is not advanced.

Local check:

```powershell
dbt source freshness --select source:pharmacy_bronze.orders_cdc
```

## Data quality

The project includes:

- `not_null`
- `unique`
- `relationships`
- `accepted_values`
- `dbt_utils.expression_is_true`
- `dbt_utils.unique_combination_of_columns`
- custom CDC consistency tests
- singular SQL business-rule tests
- dbt unit tests

Examples of business rules:

- order totals cannot be negative,
- paid orders must be fully paid,
- Gold must not expose deleted orders,
- duplicate `(key, _cdc_sequence)` events must carry the same business payload,
- `cdc_batch_control` must be unique on `(environment, pipeline_name)`.

### Unit tests

Unit tests cover `int_orders_enriched`, including:

- complete order,
- order without payment,
- order without items/payment,
- tombstone propagation,
- deleted items excluded,
- deleted payments excluded.

The production Job excludes unit tests. They run in PR CI.

## Model contracts and schema evolution

`fct_orders` uses an enforced contract:

```yaml
contract:
  enforced: true
```

Production-style incremental schema handling is:

```text
on_schema_change = fail
```

The `currency_code` schema-evolution exercise demonstrated adding a new column, declaring it in the contract, appending it to Delta, backfilling historical rows, testing it, and restoring `on_schema_change='fail'`.

For incremental models with enforced contracts in this project, use `fail` or `append_new_columns`; do not rely on `sync_all_columns`.

## Observability

### dbt execution audit

```text
workspace.ops.dbt_run_audit
```

Stores per-node execution information including:

- `dbt_invocation_id`
- `orchestrator_run_id`
- `environment`
- `cdc_batch_id`
- node/resource information
- status
- execution time
- Databricks `query_id`

The Databricks adapter in this lab does not provide reliable `rows_affected`, so row-processing observability is handled separately.

### CDC run metrics

```text
workspace.ops.cdc_run_metrics
```

Stores:

```text
requested_batch_id
watermark_before_run
orders_input_events
order_items_input_events
payments_input_events
insert_events
update_events
delete_events
total_input_events
run_status
```

### dbt artifacts

Useful generated artifacts:

```text
target/manifest.json
target/run_results.json
target/sources.json
```

`run_results.json` provides node status/timing/query IDs. `sources.json` provides freshness metadata.

## Documentation and lineage

Generate dbt documentation:

```powershell
dbt docs generate
dbt docs serve
```

The project defines a Power BI exposure:

```text
pharmacy_sales_dashboard
```

depending on `fct_orders` and `fct_daily_sales`.

Useful selector:

```powershell
dbt ls --select +exposure:pharmacy_sales_dashboard --resource-type model
```

## Local development

Environment used during development:

```text
Python 3.12
dbt Core 1.12.3
dbt-databricks 1.12.5
Windows 11 / PowerShell
```

Setup:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
pip install dbt-databricks==1.12.5

dbt deps
dbt debug
dbt parse
```

Local Databricks authentication uses CLI OAuth profile `dbt-learning`.

If OAuth expires:

```powershell
databricks auth login `
  --host https://dbc-af936830-cbe4.cloud.databricks.com `
  --profile dbt-learning
```

On local PowerShell, YAML-style vars are used:

```powershell
dbt build --select fct_orders --vars '{environment: dev, cdc_batch_id: 5}'
```

## Initial Bronze setup

Useful setup files include:

```text
setup/create_bronze_data.sql
setup/migrate_existing_raw_to_bronze.sql
setup/cleanup_legacy_schemas.sql
setup/20_simulate_adf_batch_5.sql
```

## Useful dbt commands

```powershell
dbt deps
dbt parse --no-partial-parse

dbt build --selector silver --vars '{environment: dev, cdc_batch_id: 5}'
dbt build --selector gold --vars '{environment: dev, cdc_batch_id: 5}'
dbt build --select fct_orders --vars '{environment: dev, cdc_batch_id: 5}'

dbt source freshness --select source:pharmacy_bronze.orders_cdc

dbt docs generate
dbt docs serve

dbt ls --resource-type exposure
dbt ls --select +exposure:pharmacy_sales_dashboard
```

## Databricks Asset Bundles

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

databricks bundle run `
  -t dev `
  -p dbt-learning `
  --params cdc_batch_id=5 `
  pharmacy_analytics_dbt_job
```

The Job DAG is:

```text
source_freshness
      |
      v
dbt_build
      |
      v
mark_cdc_batch_processed
```

`source_freshness` performs:

1. `dbt deps`
2. positive batch-ID validation
3. batch-has-events validation
4. source freshness

`mark_cdc_batch_processed` advances only the watermark belonging to the current environment.

## Git workflow

```text
feature/*
   |
   v
Pull Request
   |
   +--> Static dbt validation
   +--> dbt unit tests
   +--> Databricks Bundle validation
   +--> Slim dbt CI
   |
   v
merge
   |
   v
main
   |
   v
Databricks Asset Bundle deployment
```

## GitHub Actions

Pull Requests to `main` are split into four independent checks:

```text
Static dbt validation
dbt unit tests
Databricks Bundle validation
Slim dbt CI
```

Slim CI downloads the latest successful PROD `manifest.json`, evaluates `state:modified+`, and uses `--defer --favor-state`.

Each PR uses an isolated CI schema:

```text
dbt_ci_pr_<PR_NUMBER>
```

Observability hooks are disabled in CI through:

```text
enable_observability = false
```

Push/merge to `main` validates, plans and deploys the PROD Asset Bundle.

## Authentication

Current lab:

- local Databricks access: CLI OAuth profile,
- GitHub Actions lab setup: Databricks PAT stored in a GitHub Environment secret.

Production reference:

```text
GitHub Actions
      |
      | OIDC / workload identity federation
      v
Databricks service principal
```

Reference files:

```text
.github/workflows/oidc-claims.yml
docs/examples/deploy-databricks-oidc.yml
terraform/production-reference/oidc.tf
```

The full federation flow is not applied in Databricks Free Edition.

## Terraform and ownership boundaries

Terraform examples:

```text
terraform/lab/
terraform/production-reference/
```

Ownership:

```text
Terraform
  -> catalogs / schemas
  -> permissions / grants
  -> service principals
  -> SQL Warehouse infrastructure
  -> federation policy

Databricks Asset Bundles
  -> Databricks Jobs
  -> task DAG
  -> job parameters

dbt
  -> transformations
  -> tests
  -> contracts
  -> documentation
```

Do not manage the same resource with two tools.

Typical Terraform lab commands:

```powershell
terraform -chdir=terraform/lab init
terraform -chdir=terraform/lab fmt -recursive
terraform -chdir=terraform/lab validate
terraform -chdir=terraform/lab plan
terraform -chdir=terraform/lab apply
```

## ADF integration

Intended production flow:

```text
ADF ingestion
      |
      v
complete Bronze CDC batch
      |
      | cdc_batch_id
      v
Databricks Job created by Asset Bundle
      |
      v
batch validation
      |
      v
freshness gate
      |
      v
dbt build
      |
      v
Silver -> Intermediate -> Gold -> tests
      |
      v
observability
      |
      v
environment-specific watermark
```

Related documentation:

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
│       ├── oidc-claims.yml
│       └── pr-ci.yml
├── adf/
├── analyses/
├── docs/
│   └── examples/
│       └── deploy-databricks-oidc.yml
├── macros/
│   ├── cdc_batch_filter.sql
│   ├── generate_schema_name.sql
│   ├── log_cdc_run_metrics.sql
│   ├── log_dbt_run_results.sql
│   ├── mark_cdc_batch_processed.sql
│   ├── normalize_status.sql
│   ├── validate_cdc_batch_has_events.sql
│   └── validate_cdc_batch_id.sql
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   └── _control_sources.yml
│   ├── intermediate/
│   └── marts/
│       └── _exposures.yml
├── resources/
│   └── pharmacy_analytics_dbt.job.yml
├── setup/
├── snapshots/
├── terraform/
│   ├── lab/
│   └── production-reference/
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
- Terraform state files
- Terraform plan files

Commit Terraform provider lock files:

```text
.terraform.lock.hcl
```

Do not commit Terraform state:

```text
*.tfstate
*.tfstate.*
```

Production CI/CD authentication should use workload identity federation where available instead of long-lived secrets.
