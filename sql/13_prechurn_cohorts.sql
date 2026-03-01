/*
13_prechurn_cohorts.sql

PURPOSE:
    - Label each account-month with churn timing based on the logo churn definition.
    - Provide a pre-churn window that can be joined to support and usage metrics.

Dependencies
    - v_account_mrr_month

Output
    - v_account_month_cohorts (one row per account_id, month_start)

Notes
    - Churn definition:
        churn_month occurs when prev_mrr > 0 and mrr_amount = 0
    - Use the first churn month per account.
*/

SET search_path = ravenstack;

CREATE OR REPLACE VIEW v_account_month_cohorts AS
WITH base AS (
    SELECT
        month_start,
        account_id,
        mrr_amount,
        LAG(mrr_amount, 1, 0) OVER (
            PARTITION BY account_id
            ORDER BY month_start
        ) AS prev_mrr
    FROM v_account_mrr_month
),
churn_months AS (
    SELECT
        account_id,
        MIN(month_start) AS churn_month
    FROM base
    WHERE prev_mrr > 0
        AND mrr_amount = 0
    GROUP BY account_id
),
labeled AS (
    SELECT
        b.month_start,
        b.account_id,
        b.mrr_amount,
        b.prev_mrr,
        c.churn_month,

        CASE
            WHEN c.churn_month IS NULL THEN NULL
            ELSE (
                (date_part('year', c.churn_month)
                - date_part('year', b.month_start)) * 12
                + (date_part('month', c.churn_month)
                - date_part('month', b.month_start))
            )::int
        END AS months_to_churn

    FROM base b
    LEFT JOIN churn_months c
        ON c.account_id = b.account_id
    WHERE c.churn_month IS NULL
        OR b.month_start <= c.churn_month
)
SELECT
    *,
    CASE
        WHEN churn_month IS NULL THEN 'retained'
        WHEN months_to_churn = 0 THEN 'churn_month'
        WHEN months_to_churn BETWEEN 1 and 3 THEN 'pre_churn_3m'
        ELSE 'other'
    END AS cohort_label
FROM labeled;

-- 1) Grain check: should be zero
SELECT
    COUNT(*) AS bad_rows
FROM (
    SELECT
        month_start,
        account_id,
        COUNT(*) AS n
    FROM v_account_month_cohorts
    GROUP BY month_start, account_id
    HAVING COUNT(*) > 1
) t;

-- 2) Any negative months_to_churn? Should be zero
SELECT
    COUNT(*) AS negative_months
FROM v_account_month_cohorts
WHERE months_to_churn < 0;

-- 3) Row counts by cohort label
SELECT
    cohort_label,
    COUNT(*) AS rows,
    COUNT(DISTINCT account_id) AS accounts
FROM v_account_month_cohorts
GROUP BY cohort_label
ORDER BY cohort_label;

-- 4) Spot check: sample of churn_month rows
SELECT
    account_id,
    month_start,
    prev_mrr,
    mrr_amount,
    churn_month,
    months_to_churn
FROM v_account_month_cohorts
WHERE cohort_label = 'churn_month'
ORDER BY month_start DESC
LIMIT 10;