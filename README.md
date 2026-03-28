# SQL Churn Analysis Series

This repo contains the complete SQL walkthrough for the blog post churn series (published on tivon.io):

1) ["We Lost Customers, But Not Revenue (Three churn definitions in SQL)"](https://tivon.io/2026/02/11/we-lost-customers-but-not-revenue/)
   - churn definitions + scoreboard (SQL 00-10, notebook 01)
2) ["Why Are We Losing Customers (Linking support tickets and product usage to churn risk)"](https://tivon.io/2026/03/28/why-are-we-losing-customers/)
   - pre-churn signals + tier-level churn + reason codes by tier (SQL 11-19, notebook 02)

It uses a public SaaS-style dataset (Ravenstack) to walk through a practical churn workflow:

- Define churn consistently at the account-month level
- Reconcile logo churn, revenue churn, and activity churn
- Compare pre-churn behavior against retained accounts
- Segment churn patterns by plan tier
- Connect recorded churn reasons back to those tier-level patterns

* * *

## What you will reproduce

### Part 1
You will compute three churn lenses from the same underlying account-month snapshot and reconcile them in a single monthly scoreboard:

- **Logo churn**: paying last month -> not paying this month
- **Revenue churn + retention**: MRR waterfall components + NRR
- **Activity churn**: paying customers who go inactive (usage drops to zero)

You will also reproduce three supporting views used in the post visuals:

- A **Scoreboard trends** chart
- An **MRR waterfall** for a highlighted month
- **MRR mix shift by plan tier** over time

### Part 2
You will extend the same project to analyze churn drivers:

- Support burden at the account-month level
- Usage behavior at the account-month level
- Pre-churn vs retained comparisons
- Recent 3 months vs prior 3 months change signals
- Change signals segmented by plan tier
- Recorded churn reasons by plan tier

You will also reproduce three supporting visuals:

- **Change signals by tier**
- **Recorded churn reasons by tier**
- **Enterprise-focused support signal**

* * *

## Repo contents

### `data/raw/`

These are the Ravenstack CSVs loaded into Postgres:

- `ravenstack_accounts.csv`
- `ravenstack_subscriptions.csv`
- `ravenstack_feature_usage.csv`
- `ravenstack_support_tickets.csv`
- `ravenstack_churn_events.csv`

### `sql/`

Run these in order:

1. `00_create_tables.sql`  
   Creates the `ravenstack` schema and base tables.

2. `01_load_data.sql`  
   Loads CSVs via server-side `COPY` from `/data/raw`.

3. `02_profile.sql`  
   Quick profiling and validation checks (row counts, uniqueness, and basic integrity checks).

4. `03_account_mrr_month.sql`  
   `v_account_mrr_month` (one row per account-month; month-end style snapshot).

5. `04_logo_churn.sql`  
   `v_logo_churn_month` (logo churn, new customers, customer counts).

6. `05_revenue_waterfall.sql`  
   `v_revenue_waterfall_month` (MRR waterfall, gross revenue churn, NRR).

7. `06_activity_churn.sql`  
   `v_activity_churn_month` (inactive-but-paying, activity churn).

8. `07_scoreboard.sql`  
   `v_churn_scoreboard_month` (logo + revenue + activity churn reconciled in one view).

9. `08_checks.sql`  
   Reconciliation checks (MRR and customer count invariants).

10. `09_mix_shift_by_plan.sql`  
    `v_mix_shift_by_plan_month` (tier mix shift over time).

11. `10_extracts_for_python.sql`  
   Plot-ready extracts used by the notebook.

12. `11_support_metrics.sql`  
    `v_support_account_month` (support burden at the account-month grain).

13. `12_usage_metrics.sql`  
    `v_usage_account_month` (usage behavior at the account-month grain).

14. `13_prechurn_cohorts.sql`  
    `v_account_month_cohorts` (retained / churn_month / pre_churn_3m labels).

15. `14_churn_driver_table.sql`  
    `v_churn_driver_table_3m` (first joined comparison of pre-churn vs retained behavior).

16. `15_change_signals_3m.sql`  
    `v_change_signals_3m_account` (recent_3m vs prior_3m change signals per account).

17. `16_change_signals_summary.sql`  
    `v_change_signals_3m_summary` (churned vs retained summary plus coverage counts).

18. `17_change_signals_summary_by_tier.sql`  
    `v_change_signals_3m_summary_by_tier` (change signals segmented by plan tier).

19. `18_reason_code_by_tier.sql`  
    `v_reason_code_by_tier` (recorded churn reasons summarized by plan tier).

20. `19_extracts_for_python.sql`  
    Plot-ready extracts for Post #3 visuals.

### `notebooks/`
1. `01_visuals.ipynb`  
   Generates the Part 1 figures:
   - `fig_01_scoreboard_trends.png`
   - `fig_02_mrr_waterfall_2024_09.png`
   - `fig_03_mrr_mix_shift_stacked.png`

2. `02_visuals.ipynb`  
   Generates the Part 2 figures:
   - `fig_04_change_signals_by_tier.png`
   - `fig_05_reason_code_by_tier.png`
   - `fig_06_enterprise_support_signal.png`

* * *

## Key modeling decisions

### Month-end subscription snapshot

Churn math is computed on a single consistent grain: **one row per account per month**, anchored to **month close**.

**Month-end rule:** a subscription counts for a month only if it is active **as of the last day of the month**.

Accounts can have overlapping subscription rows. `v_account_mrr_month` resolves this by selecting one “winner” subscription per account-month using a deterministic ranking rule:

- latest `start_date`
- then highest `mrr_amount`
- then `subscription_id`

That avoids double-counting and makes month-over-month comparisons stable.

**Account-month spine:** month-end snapshots omit non-paying months, so downstream churn views build a complete account-month spine (every account × every month) and fill missing months with zeros. This ensures month-to-month comparisons are truly adjacent calendar months instead of “previous paying month”.

### `feature_usage_raw` is intentionally a landing table

The source usage file can contain duplicate `usage_id` values. The table uses a surrogate `row_id` (bigserial) instead of enforcing a primary key on `usage_id`.

Downstream usage logic aggregates usage to the account-month level.

### Part 2 uses the Part 1 logo-churn anchor
The pre-churn analysis does not create a new churn definition. It reuses the Part 1 logo-churn anchor:

- `prev_mrr > 0`
- `mrr_amount = 0`

That churn month becomes the anchor for recent 3-month vs prior 3-month comparisons.

* * *

## Checks (trust before interpretation)

### Part 1 checks
`08_checks.sql` validates two invariants:

1. **MRR waterfall reconciliation**  
   `starting + new + expansion - contraction - churned = ending`

2. **Customer reconciliation**  
   `customers_end = customers_start + new_customers - churned_customers`

If diffs are non-zero, stop and debug before interpreting churn.

### Part 2 checks
The Part 2 workflow adds three additional layers of validation:

- support metrics are one row per `(account_id, month_start)`
- usage metrics are one row per `(account_id, month_start)`
- pre-churn windows are aligned to the first logo-churn month and exclude post-churn months

Coverage counts are also carried into the summary views so sparse percent changes can be interpreted correctly.

* * *

## Prerequisites

- Docker Desktop
- A PostgreSQL container (this repo uses Postgres 18)
- `psql` available inside the container (standard for official postgres images)
- Optional: VS Code + PostgreSQL extension (or SQLTools)
- Optional (for visuals): Python + Jupyter (see `requirements.txt`)

* * *

## Quickstart (PowerShell)

### 1) Clone the repo

    cd $HOME
    git clone https://github.com/tivonio/sql-churn-analysis.git
    cd sql-churn-analysis

### 2) Start PostgreSQL with Docker Compose (recommended)

    docker compose up -d

Confirm the container is running:

    docker ps

You should see a container named `pg18`.

* * *

## Load the Ravenstack dataset

This project uses server-side `COPY`, which means the CSV path must be visible to the Postgres server.

The included `docker-compose.yml` mounts:

- `./data/raw` (host) → `/data/raw` (container, read-only)

So `/data/raw/*.csv` exists inside the container.

### Option 1: Run via `psql` in the container

If you want to run the SQL files *from inside the container*, the SQL scripts need to be accessible inside the container too.

The simplest approach is to mount the repo into the container (for example: `/workspace`) by adding this to your compose service volumes:

    - ./:/workspace

Then run (example):

    docker exec -it pg18 psql -U postgres -d lab -f /workspace/sql/00_create_tables.sql
    docker exec -it pg18 psql -U postgres -d lab -f /workspace/sql/01_load_data.sql

### Option 2 (recommended for learning): Run inside VS Code

1. Open the repo folder in VS Code.
2. Use the PostgreSQL extension to connect to the container database.
   - Host: `localhost`
   - Port: `5434` (from `docker-compose.yml`)
   - Database: `lab`
   - User: `postgres`
3. Open a file in `sql/` and run the statements from the editor (in order).

This keeps your workflow inside `.sql` files, which is ideal for learning and for clean GitHub diffs.

* * *

## Generate the figures (optional)

The notebook reads from the SQL extracts and produces the three post figures.

If you are using a virtual environment:

    python -m venv .venv
    .\.venv\Scripts\activate
    pip install -r requirements.txt

Then open:
`01_visuals.ipynb` for Part 1 figures
`02_visuals.ipynb` for Part 2 figures

* * *

## Reset the project (start over clean)

Resetting is useful when you want to reproduce the walkthrough from scratch.

### If you used Docker Compose

    docker compose down -v
    docker compose up -d

* * *

## Notes

- If `01_load_data.sql` fails with file path errors, the most common cause is that `/data/raw` is not mounted into the container.
- If you are running `psql` from your host machine (client-side), use `\copy` instead of `COPY` so the file path resolves on the client. 
- `.gitignore` excludes typical local artifacts.
- `requirements.txt` pins the Python environment used for the notebook (pandas/matplotlib/psycopg2, plus Jupyter dependencies).