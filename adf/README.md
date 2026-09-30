# ADF integration

`databricks_job_activity.template.json` is an activity template, not a complete ADF pipeline export.

In ADF:

1. Create or use an Azure Databricks linked service.
2. Prefer System Assigned Managed Identity when supported by the environment.
3. Add a `Job` activity.
4. Select the Databricks linked service.
5. Select the existing Databricks Job.
6. Make it depend on successful completion of Bronze ingestion.
7. Make downstream activities depend on successful completion of the Job activity.

In exported pipeline JSON, the activity type is `DatabricksJob` and `jobId` identifies the
saved Databricks Job.
