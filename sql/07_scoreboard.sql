/*
07_scoreboard.sql

PURPOSE:
    - Combine the three churn views into one monthly scoreboard:
        1) Logo churn (customer loss)
        2) revenue movement + retention (Finance view)
        3) activity churn (product performance indicator)

Significance
    - SQL 07 is the main deliverable.
    - It reconciles the three definitions of churn in one place.
    - Showing the definitions side by side helps ground the conversation in specifics.

Dependencies
    - Requires:
        - v_logo_churn_month (04_logo_churn.sql)
        - v_revenue_waterfall_month (05_revenue_waterfall.sql)
        - v_activity_churn_month (06_activity_churn.sql)

Output
    - v_churn_scoreboard_month

Notes
    - This view is designed for interpretation and communication.
    - It is the source for the main table and Python visuals in SQL 10 & notebook 01.
*/

SET search_path = ravenstack;

CREATE OR REPLACE VIEW v_churn_scoreboard_month AS
SELECT
    l.month_start,
    l.new_customers,
    l.churned_customers,
    l.customers_end,
    l.logo_churn_rate,

    r.starting_mrr,
    r.new_mrr,
    r.expansion_mrr,
    r.contraction_mrr,
    r.churned_mrr,
    r.ending_mrr,
    r.gross_revenue_churn_rate,
    r.net_revenue_retention,

    a.paying_accounts,
    a.active_paying_accounts,
    a.inactive_but_paying_accounts,
    a.activity_churned_accounts,
    a.activity_churn_rate
FROM v_logo_churn_month l
LEFT JOIN v_revenue_waterfall_month r USING (month_start)
LEFT JOIN v_activity_churn_month a USING (month_start)
ORDER BY l.month_start;

/* Interpretation:
 - If logo churn is high, but ending_mrr is rising,
    check whether new_mrr/expansion_mrr are offsetting losses.
 - If revenue is stable, but activity churn is rising,
    treat is as future churn risk.
*/

-- Optional: view first 10 rows.
SELECT *
FROM v_churn_scoreboard_month
LIMIT 10;