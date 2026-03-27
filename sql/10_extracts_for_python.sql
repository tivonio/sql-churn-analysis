/*
10_extracts_for_python.sql

PURPOSE:
    - Create plot-ready extracts for Python.
    - Keep SQL as the baseline and use Python only to visualize outputs.

Significance
    - SQL 10 bridges the SQL analysis to the notebook used for visuals.
    - It keeps the plotting layer clean and reproducible.
    - The SQL views remain the source of truth.

Dependencies
    - Requires:
        - v_churn_scoreboard_month (07_scoreboard.sql)
        - v_revenue_waterfall_month (05_revenue_waterfall.sql)
        - v_mix_shift_by_plan_month (09_mix_shift_by_plan.sql)

Output
    - Query results for:
        - scoreboard trends
        - MRR waterfall inputs
        - mix shift by plan tier

Notes
    - This file does not create persistent views.
    - It is designed to be consumed by notebook 01_visual.ipynb.
*/

-- Visual 1: Scoreboard trends
SELECT
    month_start,
    logo_churn_rate,
    net_revenue_retention,
    activity_churn_rate
FROM ravenstack.v_churn_scoreboard_month
ORDER BY month_start;

-- Visual 2: Revenue waterfall input (filter one month in Python)
SELECT
    month_start,
    starting_mrr,
    new_mrr,
    expansion_mrr,
    contraction_mrr,
    churned_mrr,
    ending_mrr
FROM ravenstack.v_revenue_waterfall_month
ORDER BY month_start;

-- Visual 3: Mix shift by plan tier
SELECT
    month_start,
    plan_tier,
    paying_accounts,
    total_mrr,
    avg_mrr_per_account
FROM ravenstack.v_mix_shift_by_plan_month
ORDER BY month_start, plan_tier;