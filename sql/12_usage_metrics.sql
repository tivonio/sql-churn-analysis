/*
12_usage_metrics.sql

PURPOSE:
    - Create account-month product usage metrics aligned to churn timing.

significance
    - Usage decline is often a leading indicator before churn.
    - Usage is rolled up to the same grain as the churn shanpshot: account-month.

Output
    - v_usage_account_month

Notes
    - feature_usage_raw may contain duplicate usage_id values
    - This is acceptable here because usage is aggregated to account-month.
*/

SET search_path = ravenstack;

CREATE OR REPLACE VIEW v_usage_account_month AS
WITH usage_with_account AS (
    SELECT
        s.account_id,
        DATE_TRUNC('month', u.usage_date)::date AS month_start,
        u.feature_name,
        COALESCE(u.usage_count, 0) AS usage_count
    FROM feature_usage_raw u
    JOIN subscriptions s
        ON s.subscription_id = u.subscription_id
),
monthly AS (
    SELECT
        month_start,
        account_id,
        SUM(usage_count) AS total_usage_count,
        COUNT(DISTINCT feature_name) AS distinct_features_used
    FROM usage_with_account
    GROUP BY 1, 2
)
SELECT
    month_start,
    account_id,
    total_usage_count,
    distinct_features_used,
    CASE
        WHEN total_usage_count > 0 THEN 1
        ELSE 0
    END AS active_flag
FROM monthly;

-- QC checks
-- 1) Grain check: should be zero
SELECT
    COUNT(*) AS bad_rows
FROM (
    SELECT
        month_start,
        account_id,
        COUNT(*) as n
    FROM v_usage_account_month
    GROUP BY 1, 2
    HAVING COUNT(*) > 1
) t;

-- 2) Date range check
SELECT
    MIN(month_start) AS min_month,
    MAX(month_start) AS max_month,
    COUNT(*) AS rows
FROM v_usage_account_month;

-- 3) Quick distribution checks
SELECT
    AVG(total_usage_count) AS avg_total_usage,
    MAX(total_usage_count) AS max_total_usage,
    AVG(distinct_features_used) AS avg_distinct_features,
    MAX(distinct_features_used) AS max_distinct_features
FROM v_usage_account_month;