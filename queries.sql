-- ============================================
-- TASK 1 — SQL QUERIES (POSTGRESQL)
-- ============================================


-- ============================================
-- Q1: For each subscription plan, calculate:
--     - Number of active customers
--     - Average monthly revenue
--     - Support ticket rate (tickets per customer per month)
--     over the last 6 months
-- ============================================

SET search_path TO nimbus, public;

SELECT
    p.plan_name,
    p.plan_tier,
    COUNT(DISTINCT s.customer_id)                        AS active_customers,
    ROUND(AVG(s.mrr_usd), 2)                             AS avg_monthly_revenue_usd,
    COUNT(DISTINCT st.ticket_id)                         AS total_tickets_6mo,
    ROUND(
        COUNT(DISTINCT st.ticket_id)::NUMERIC
        / NULLIF(COUNT(DISTINCT s.customer_id) * 6, 0),
        3
    )                                                    AS tickets_per_customer_per_month
FROM nimbus.subscriptions s
JOIN nimbus.plans p
    ON s.plan_id = p.plan_id
LEFT JOIN nimbus.support_tickets st
    ON  st.customer_id = s.customer_id
    AND st.created_at >= CURRENT_DATE - INTERVAL '6 months'
WHERE s.status = 'active'
GROUP BY
    p.plan_id,
    p.plan_name,
    p.plan_tier
ORDER BY avg_monthly_revenue_usd DESC;



-- ============================================
-- Q2: Rank customers within each plan tier by total lifetime value.
--     Also calculate the percentage difference from the tier average.
-- ============================================

WITH customer_ltv AS (
    SELECT
        s.customer_id,
        c.company_name,
        p.plan_name,
        p.plan_tier,
        ROUND(SUM(s.mrr_usd), 2) AS ltv_usd
    FROM nimbus.subscriptions s
    JOIN nimbus.customers c ON c.customer_id = s.customer_id
    JOIN nimbus.plans p     ON p.plan_id     = s.plan_id
    GROUP BY
        s.customer_id,
        c.company_name,
        p.plan_name,
        p.plan_tier
)

SELECT
    customer_id,
    company_name,
    plan_name,
    plan_tier,
    ltv_usd,
    RANK() OVER (
        PARTITION BY plan_tier
        ORDER BY ltv_usd DESC
    ) AS rank_in_tier,
    ROUND(
        AVG(ltv_usd) OVER (PARTITION BY plan_tier),
        2
    ) AS tier_avg_ltv_usd,
    ROUND(
        (ltv_usd - AVG(ltv_usd) OVER (PARTITION BY plan_tier))
        / NULLIF(AVG(ltv_usd) OVER (PARTITION BY plan_tier), 0)
        * 100,
        1
    ) AS pct_diff_from_tier_avg
FROM customer_ltv
ORDER BY plan_tier, rank_in_tier;



-- ============================================
-- Q3: Identify customers who downgraded their plan
--     and had support tickets before downgrade
-- ============================================

SET search_path TO nimbus, public;

SELECT
    s_new.customer_id,
    c.company_name,
    p_old.plan_name         AS previous_plan,
    p_old.plan_tier         AS previous_tier,
    p_old.monthly_price_usd AS previous_price_usd,
    p_new.plan_name         AS current_plan,
    p_new.plan_tier         AS current_tier,
    p_new.monthly_price_usd AS current_price_usd,
    ROUND(p_old.monthly_price_usd
        - p_new.monthly_price_usd, 2)  AS monthly_revenue_lost,
    s_new.start_date        AS downgrade_date,
    COUNT(st.ticket_id)     AS tickets_before_downgrade
FROM nimbus.subscriptions s_new
JOIN nimbus.subscriptions s_old
    ON  s_new.customer_id = s_old.customer_id
    AND s_new.start_date  > s_old.start_date
JOIN nimbus.plans p_new ON s_new.plan_id = p_new.plan_id
JOIN nimbus.plans p_old ON s_old.plan_id = p_old.plan_id
JOIN nimbus.customers c ON s_new.customer_id = c.customer_id
LEFT JOIN nimbus.support_tickets st
    ON  st.customer_id = s_new.customer_id
    AND st.created_at >= s_new.start_date - INTERVAL '30 days'
    AND st.created_at <  s_new.start_date
WHERE
    p_new.monthly_price_usd < p_old.monthly_price_usd
GROUP BY
    s_new.customer_id,
    c.company_name,
    p_old.plan_name,
    p_old.plan_tier,
    p_old.monthly_price_usd,
    p_new.plan_name,
    p_new.plan_tier,
    p_new.monthly_price_usd,
    s_new.start_date
HAVING COUNT(st.ticket_id) >= 1
ORDER BY tickets_before_downgrade DESC
LIMIT 20;



-- ============================================
-- Q4: Calculate monthly subscription trends and churn analysis
--     with rolling 3-month average and churn spike detection
-- ============================================

SET search_path TO nimbus, public;

SELECT
    DATE_TRUNC('month', s.start_date)       AS month,
    p.plan_tier,
    COUNT(CASE WHEN s.start_date IS NOT NULL
               THEN 1 END)                  AS new_subscriptions,
    COUNT(CASE WHEN s.status IN ('cancelled','churned')
               AND s.end_date IS NOT NULL
               THEN 1 END)                  AS churned,
    ROUND(AVG(COUNT(
        CASE WHEN s.status IN ('cancelled','churned')
             AND s.end_date IS NOT NULL
             THEN 1 END))
        OVER (
            PARTITION BY p.plan_tier
            ORDER BY DATE_TRUNC('month', s.start_date)
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 1)                               AS rolling_3mo_avg_churn,
    CASE
        WHEN COUNT(CASE WHEN s.status IN ('cancelled','churned')
                        AND s.end_date IS NOT NULL
                        THEN 1 END)
             > 2 * AVG(COUNT(
                 CASE WHEN s.status IN ('cancelled','churned')
                      AND s.end_date IS NOT NULL
                      THEN 1 END))
               OVER (
                   PARTITION BY p.plan_tier
                   ORDER BY DATE_TRUNC('month', s.start_date)
                   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
               )
        THEN 'CHURN SPIKE'
        ELSE 'Normal'
    END                                     AS churn_alert
FROM nimbus.subscriptions s
JOIN nimbus.plans p ON s.plan_id = p.plan_id
WHERE s.start_date IS NOT NULL
GROUP BY
    DATE_TRUNC('month', s.start_date),
    p.plan_tier
ORDER BY p.plan_tier, month;



-- ============================================
-- Q5: Detect potential duplicate customers based on
--     name similarity and email domain matching
-- ============================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

SET search_path TO nimbus, public;

SELECT
    a.customer_id                           AS customer_id_1,
    b.customer_id                           AS customer_id_2,
    a.company_name                          AS company_name_1,
    b.company_name                          AS company_name_2,
    LOWER(SPLIT_PART(a.contact_email,'@',2)) AS domain_1,
    LOWER(SPLIT_PART(b.contact_email,'@',2)) AS domain_2,
    ROUND(SIMILARITY(
        LOWER(a.company_name),
        LOWER(b.company_name)
    )::numeric, 2)                          AS name_similarity,
    CASE
        WHEN LOWER(SPLIT_PART(a.contact_email,'@',2))
           = LOWER(SPLIT_PART(b.contact_email,'@',2))
        THEN 'YES' ELSE 'NO'
    END                                     AS same_email_domain,
    CASE
        WHEN ROUND(SIMILARITY(
                LOWER(a.company_name),
                LOWER(b.company_name))::numeric, 2) > 0.85
             AND LOWER(SPLIT_PART(a.contact_email,'@',2))
               = LOWER(SPLIT_PART(b.contact_email,'@',2))
        THEN 'HIGH - Very likely duplicate'
        WHEN ROUND(SIMILARITY(
                LOWER(a.company_name),
                LOWER(b.company_name))::numeric, 2) > 0.70
        THEN 'MEDIUM - Possible duplicate'
        ELSE 'LOW - Weak signal'
    END                                     AS duplicate_confidence
FROM nimbus.customers a
JOIN nimbus.customers b
    ON  a.customer_id < b.customer_id
    AND (
        SIMILARITY(
            LOWER(a.company_name),
            LOWER(b.company_name)
        ) > 0.5
        OR
        LOWER(SPLIT_PART(a.contact_email,'@',2))
      = LOWER(SPLIT_PART(b.contact_email,'@',2))
    )
WHERE a.contact_email IS NOT NULL
  AND b.contact_email IS NOT NULL
ORDER BY name_similarity DESC
LIMIT 20;