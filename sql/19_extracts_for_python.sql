/*
19_extracts_for_python.sql

PURPOSE:
    - Create plot-ready extracts for Python.
    - Keep SQL as the baseline and use Python only for visualization.

Significance
    - SQL 19 is the bridge from the SQL analysis to the notebook.
    - It packages the tier-level churn signal comparisons and reason code summaries
        into aclean extracts for plotting.
    - This file keeps the Python notebook focused on charting rather that business logic.

Dependencies
    - Requires:
        - v_change_signals_3m_summary_by_tier (17_change_signals_summary_by_tier.sql)
        - v_reason_code_by_tier (18_reason_code_by_tier.sql)

Output
    - Query results for:
        - Change signal by tier
        - Reason codes by tier
        - Enterprise-focused support signal

Notes
    - This file does not create persistent views.
    - The notebook should read these extracts directly and avoid re-implementing logic.
*/

-- Visual 1: Change signals by tier
SELECT
    anchor_type,
    plan_tier,
    avg_tickets_delta,
    avg_high_priority_delta,
    avg_usage_delta
FROM ravenstack.v_change_signals_3m_summary_by_tier
ORDER BY
    plan_tier,
    anchor_type;

-- Visual 2: Reason code by tier
SELECT
    plan_tier,
    reason_code,
    churned_accounts,
    tier_churned_accounts,
    share_within_tier
FROM ravenstack.v_reason_code_by_tier
ORDER BY
    plan_tier,
    churned_accounts DESC,
    reason_code;

-- Visual 3: Enterprise-focused support signal
SELECT
    anchor_type,
    plan_tier,
    avg_tickets_delta,
    avg_high_priority_delta,
    avg_usage_delta
FROM ravenstack.v_change_signals_3m_summary_by_tier
WHERE plan_tier = 'Enterprise'
ORDER BY anchor_type;