/*
09_mix_shift_by_plan.sql

PURPOSE:
    - Summarize paying accounts and MRR by plan_tier over time.
    - Show how revenue composition changes across Basic, Pro, and Enterprise.

Significance
    - SQL 09 shows how MRR is distributed across Basic, Pro, and Enterprise
        at the month-end snapshot grain.
    - It makes mix shift visible by separating changes in customer count from
        changes in revenue contribution by tier.
    - Total MRR can rise even if a segment shrinks, if customers migrate
        to higher tiers or the business acquires more high_value customers.

Dependencies
    - Requires:
        - v_account_mrr_month (03_account_mrr_month.sql)

Output
    - v_mix_shift_by_plan_month

Notes
    - This view is used to compare plan-tier counts, total MRR, and average MRR
        per account over time.
    - It is most useful when read alongside the churn scoreboard and MRR waterfall.
*/

SET search_path = ravenstack;

CREATE OR REPLACE VIEW v_mix_shift_by_plan_month AS
SELECT
    month_start,
    plan_tier,
    COUNT(*) FILTER (
        WHERE mrr_amount > 0
    ) AS paying_accounts,
    SUM(mrr_amount) FILTER (
        WHERE mrr_amount > 0
    ) AS total_mrr,
    AVG(mrr_amount) FILTER (
        WHERE mrr_amount > 0
    ) AS avg_mrr_per_account
FROM v_account_mrr_month
GROUP BY 1, 2
ORDER BY month_start, plan_tier;

SELECT *
FROM v_mix_shift_by_plan_month;