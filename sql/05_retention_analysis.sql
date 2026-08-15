-- ============================================
-- FinSight - Cohort Retention Analysis 21K
-- ============================================

WITH user_cohorts AS (

    SELECT
        user_id,
        DATE_TRUNC('month', signup_date)::DATE AS cohort_month
    FROM users

),

monthly_activity AS (

    SELECT
        user_id,
        DATE_TRUNC(
            'month',
            transaction_date
        )::DATE AS activity_month

    FROM transactions

    WHERE status = 'Successful'

    GROUP BY
        user_id,
        DATE_TRUNC(
            'month',
            transaction_date
        )::DATE
),

cohort_activity AS (

    SELECT
        uc.cohort_month,
        ma.activity_month,
        COUNT(DISTINCT uc.user_id) AS active_users

    FROM user_cohorts uc

    JOIN monthly_activity ma
        ON uc.user_id = ma.user_id

    GROUP BY
        uc.cohort_month,
        ma.activity_month
),

cohort_sizes AS (

    SELECT
        cohort_month,
        COUNT(*) AS cohort_users

    FROM user_cohorts

    GROUP BY cohort_month
)

SELECT
    ca.cohort_month,
    ca.activity_month,
    cs.cohort_users,
    ca.active_users,

    ROUND(
        100.0 * ca.active_users
        / cs.cohort_users,
        2
    ) AS retention_rate

FROM cohort_activity ca

JOIN cohort_sizes cs
    ON ca.cohort_month = cs.cohort_month

ORDER BY
    ca.cohort_month,
    ca.activity_month;

-- ============================================
-- Cohort Retention  Matrix 21L
-- ============================================


WITH user_cohorts AS (

    SELECT
        user_id,
        DATE_TRUNC('month', signup_date)::DATE AS cohort_month
    FROM users

),

monthly_activity AS (

    SELECT
        user_id,
        DATE_TRUNC(
            'month',
            transaction_date
        )::DATE AS activity_month

    FROM transactions

    WHERE status = 'Successful'

    GROUP BY
        user_id,
        DATE_TRUNC(
            'month',
            transaction_date
        )::DATE
),

cohort_activity AS (

    SELECT
        uc.cohort_month,
        ma.activity_month,
        COUNT(DISTINCT uc.user_id) AS active_users

    FROM user_cohorts uc

    JOIN monthly_activity ma
        ON uc.user_id = ma.user_id

    GROUP BY
        uc.cohort_month,
        ma.activity_month
),

cohort_sizes AS (

    SELECT
        cohort_month,
        COUNT(*) AS cohort_users
    FROM user_cohorts
    GROUP BY cohort_month
),

retention AS (

    SELECT
        ca.cohort_month,

        (
            EXTRACT(
                YEAR FROM AGE(
                    ca.activity_month,
                    ca.cohort_month
                )
            ) * 12
            +
            EXTRACT(
                MONTH FROM AGE(
                    ca.activity_month,
                    ca.cohort_month
                )
            )
        )::INT AS month_number,

        ROUND(
            100.0 * ca.active_users / cs.cohort_users,
            2
        ) AS retention_rate

    FROM cohort_activity ca

    JOIN cohort_sizes cs
        ON ca.cohort_month = cs.cohort_month
)

SELECT
    cohort_month,

    MAX(retention_rate)
        FILTER (WHERE month_number = 0) AS month_0,

    MAX(retention_rate)
        FILTER (WHERE month_number = 1) AS month_1,

    MAX(retention_rate)
        FILTER (WHERE month_number = 2) AS month_2,

    MAX(retention_rate)
        FILTER (WHERE month_number = 3) AS month_3,

    MAX(retention_rate)
        FILTER (WHERE month_number = 4) AS month_4,

    MAX(retention_rate)
        FILTER (WHERE month_number = 5) AS month_5,

    MAX(retention_rate)
        FILTER (WHERE month_number = 6) AS month_6,

    MAX(retention_rate)
        FILTER (WHERE month_number = 7) AS month_7,

    MAX(retention_rate)
        FILTER (WHERE month_number = 8) AS month_8,

    MAX(retention_rate)
        FILTER (WHERE month_number = 9) AS month_9,

    MAX(retention_rate)
        FILTER (WHERE month_number = 10) AS month_10,

    MAX(retention_rate)
        FILTER (WHERE month_number = 11) AS month_11,

    MAX(retention_rate)
        FILTER (WHERE month_number = 12) AS month_12

FROM retention

GROUP BY cohort_month

ORDER BY cohort_month;
-- ============================================
-- Activation Analysis  22 
-- ============================================
WITH activation AS (

    SELECT
        u.user_id,
        u.signup_date,
        u.kyc_status,

        COUNT(t.transaction_id) AS successful_transactions_30d

    FROM users u

    LEFT JOIN transactions t
        ON u.user_id = t.user_id
        AND t.status = 'Successful'
        AND t.transaction_date >= u.signup_date
        AND t.transaction_date < u.signup_date + INTERVAL '30 days'

    GROUP BY
        u.user_id,
        u.signup_date,
        u.kyc_status
)

SELECT
    COUNT(*) AS total_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
        AND successful_transactions_30d > 0
    ) AS activated_users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
            AND successful_transactions_30d > 0
        )
        / COUNT(*),
        2
    ) AS activation_rate

FROM activation;
-- ============================================
-- Activation Retention  22A
-- ============================================

WITH activation AS (

    SELECT
        u.user_id,
        u.signup_date,

        CASE
            WHEN u.kyc_status = 'Completed'
                 AND COUNT(t.transaction_id) > 0
            THEN 1
            ELSE 0
        END AS is_activated

    FROM users u

    LEFT JOIN transactions t
        ON u.user_id = t.user_id
        AND t.status = 'Successful'
        AND t.transaction_date >= u.signup_date
        AND t.transaction_date < u.signup_date + INTERVAL '30 days'

    GROUP BY
        u.user_id,
        u.signup_date,
        u.kyc_status
),

month_1_activity AS (

    SELECT DISTINCT
        a.user_id

    FROM activation a

    JOIN transactions t
        ON a.user_id = t.user_id

    WHERE
        t.status = 'Successful'
        AND t.transaction_date >=
            a.signup_date + INTERVAL '1 month'
        AND t.transaction_date <
            a.signup_date + INTERVAL '2 months'
)

SELECT
    CASE
        WHEN a.is_activated = 1
            THEN 'Activated'
        ELSE 'Not Activated'
    END AS activation_group,

    COUNT(*) AS users,

    COUNT(m.user_id) AS month_1_retained_users,

    ROUND(
        100.0 * COUNT(m.user_id) / COUNT(*),
        2
    ) AS month_1_retention_rate

FROM activation a

LEFT JOIN month_1_activity m
    ON a.user_id = m.user_id

GROUP BY
    a.is_activated

ORDER BY
    a.is_activated DESC;

-- ============================================
-- Find the Activation Funnel  22B
-- ============================================
WITH user_activation AS (

    SELECT
        u.user_id,
        u.kyc_status,

        COUNT(t.transaction_id) AS successful_transactions_30d

    FROM users u

    LEFT JOIN transactions t
        ON u.user_id = t.user_id
        AND t.status = 'Successful'
        AND t.transaction_date >= u.signup_date
        AND t.transaction_date < u.signup_date + INTERVAL '30 days'

    GROUP BY
        u.user_id,
        u.kyc_status
)

SELECT
    COUNT(*) AS total_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
    ) AS kyc_completed_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
        AND successful_transactions_30d > 0
    ) AS activated_users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
        ) / COUNT(*),
        2
    ) AS kyc_completion_rate,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
            AND successful_transactions_30d > 0
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE kyc_status = 'Completed'
            ),
            0
        ),
        2
    ) AS kyc_to_activation_rate

FROM user_activation;

-- ============================================
-- Activation by acquisition channel  23
-- ============================================
WITH activation AS (

    SELECT
        u.user_id,
        u.acquisition_channel,
        u.kyc_status,

        COUNT(t.transaction_id) AS successful_transactions_30d

    FROM users u

    LEFT JOIN transactions t
        ON u.user_id = t.user_id
        AND t.status = 'Successful'
        AND t.transaction_date >= u.signup_date
        AND t.transaction_date < u.signup_date + INTERVAL '30 days'

    GROUP BY
        u.user_id,
        u.acquisition_channel,
        u.kyc_status
)

SELECT
    acquisition_channel,

    COUNT(*) AS users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
    ) AS kyc_completed_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
        AND successful_transactions_30d > 0
    ) AS activated_users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
        )
        / COUNT(*),
        2
    ) AS kyc_completion_rate,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
            AND successful_transactions_30d > 0
        )
        / COUNT(*),
        2
    ) AS activation_rate

FROM activation

GROUP BY acquisition_channel

ORDER BY activation_rate DESC;


-- ============================================
-- Activation by age group  24
-- ============================================
WITH activation AS (

    SELECT
        u.user_id,
        u.age_group,
        u.kyc_status,

        COUNT(t.transaction_id) AS successful_transactions_30d

    FROM users u

    LEFT JOIN transactions t
        ON u.user_id = t.user_id
        AND t.status = 'Successful'
        AND t.transaction_date >= u.signup_date
        AND t.transaction_date < u.signup_date + INTERVAL '30 days'

    GROUP BY
        u.user_id,
        u.age_group,
        u.kyc_status
)

SELECT
    age_group,

    COUNT(*) AS users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
    ) AS kyc_completed_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
        AND successful_transactions_30d > 0
    ) AS activated_users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
        )
        / COUNT(*),
        2
    ) AS kyc_completion_rate,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
            AND successful_transactions_30d > 0
        )
        / COUNT(*),
        2
    ) AS activation_rate

FROM activation

GROUP BY age_group

ORDER BY activation_rate DESC;

-- ============================================
-- Activation by device type  25
-- ============================================

WITH activation AS (

    SELECT
        u.user_id,
        u.device_type,
        u.kyc_status,

        COUNT(t.transaction_id) AS successful_transactions_30d

    FROM users u

    LEFT JOIN transactions t
        ON u.user_id = t.user_id
        AND t.status = 'Successful'
        AND t.transaction_date >= u.signup_date
        AND t.transaction_date < u.signup_date + INTERVAL '30 days'

    GROUP BY
        u.user_id,
        u.device_type,
        u.kyc_status
)

SELECT
    device_type,

    COUNT(*) AS users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
    ) AS kyc_completed_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
        AND successful_transactions_30d > 0
    ) AS activated_users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
        )
        / COUNT(*),
        2
    ) AS kyc_completion_rate,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
            AND successful_transactions_30d > 0
        )
        / COUNT(*),
        2
    ) AS activation_rate

FROM activation

GROUP BY device_type

ORDER BY activation_rate DESC;

-- ============================================
-- Behavioral comparison 26 TIME CONSUMING Query
-- ============================================

WITH user_activity AS (

    SELECT
        u.user_id,
        u.signup_date,

        CASE
            WHEN EXISTS (
                SELECT 1
                FROM transactions t
                WHERE t.user_id = u.user_id
                  AND t.status = 'Successful'
                  AND t.transaction_date >=
                      u.signup_date + INTERVAL '1 month'
                  AND t.transaction_date <
                      u.signup_date + INTERVAL '2 months'
            )
            THEN 1
            ELSE 0
        END AS retained_month_1

    FROM users u
),

behavior AS (

    SELECT
        ua.user_id,
        ua.retained_month_1,

        COUNT(*) FILTER (
            WHERE pe.event_type = 'app_open'
        ) AS app_opens,

        COUNT(*) FILTER (
            WHERE pe.event_type = 'product_view'
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE pe.event_type = 'product_click'
        ) AS product_clicks,

        COUNT(*) FILTER (
            WHERE pe.event_type = 'transaction_start'
        ) AS transaction_starts,

        COUNT(*) FILTER (
            WHERE pe.event_type = 'feature_used'
        ) AS features_used,

        COUNT(*) FILTER (
            WHERE pe.event_type = 'transaction_failed'
        ) AS failed_transactions

    FROM user_activity ua

    LEFT JOIN product_events pe
        ON ua.user_id = pe.user_id

    GROUP BY
        ua.user_id,
        ua.retained_month_1
)

SELECT
    CASE
        WHEN retained_month_1 = 1
            THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END AS user_group,

    COUNT(*) AS users,

    ROUND(AVG(app_opens), 2) AS avg_app_opens,

    ROUND(AVG(product_views), 2) AS avg_product_views,

    ROUND(AVG(product_clicks), 2) AS avg_product_clicks,

    ROUND(AVG(transaction_starts), 2) AS avg_transaction_starts,

    ROUND(AVG(features_used), 2) AS avg_features_used,

    ROUND(AVG(failed_transactions), 2) AS avg_failed_transactions

FROM behavior

GROUP BY retained_month_1

ORDER BY retained_month_1 DESC;
-- ============================================
-- Behavior vs Month-1 Retention  26 MINI .
-- ============================================
WITH event_summary AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'app_open'
        ) AS app_opens,

        COUNT(*) FILTER (
            WHERE event_type = 'product_view'
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE event_type = 'product_click'
        ) AS product_clicks,

        COUNT(*) FILTER (
            WHERE event_type = 'transaction_start'
        ) AS transaction_starts,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS features_used,

        COUNT(*) FILTER (
            WHERE event_type = 'transaction_failed'
        ) AS failed_transactions

    FROM product_events

    GROUP BY user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'

      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'

      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
)

SELECT
    CASE
        WHEN m.user_id IS NOT NULL
        THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END AS user_group,

    COUNT(*) AS users,

    ROUND(AVG(COALESCE(e.app_opens, 0)), 2)
        AS avg_app_opens,

    ROUND(AVG(COALESCE(e.product_views, 0)), 2)
        AS avg_product_views,

    ROUND(AVG(COALESCE(e.product_clicks, 0)), 2)
        AS avg_product_clicks,

    ROUND(AVG(COALESCE(e.transaction_starts, 0)), 2)
        AS avg_transaction_starts,

    ROUND(AVG(COALESCE(e.features_used, 0)), 2)
        AS avg_features_used,

    ROUND(AVG(COALESCE(e.failed_transactions, 0)), 2)
        AS avg_failed_transactions

FROM users u

LEFT JOIN event_summary e
    ON u.user_id = e.user_id

LEFT JOIN month_1_retention m
    ON u.user_id = m.user_id

GROUP BY
    CASE
        WHEN m.user_id IS NOT NULL
        THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END;

-- ============================================
--  making index  26
-- ============================================
CREATE INDEX IF NOT EXISTS idx_transactions_user_date
ON transactions (user_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_events_user
ON product_events (user_id);

CREATE INDEX IF NOT EXISTS idx_events_user_timestamp
ON product_events (user_id, event_timestamp);


-- ============================================
-- First 30-Day Product Behavior vs Month-1 Retention STEP 26A
-- ============================================
WITH user_behavior AS (

    SELECT
        u.user_id,

        COUNT(*) FILTER (
            WHERE e.event_type = 'app_open'
        ) AS app_opens,

        COUNT(*) FILTER (
            WHERE e.event_type = 'product_view'
        ) AS product_views,

        COUNT(*) FILTER (
            WHERE e.event_type = 'product_click'
        ) AS product_clicks,

        COUNT(*) FILTER (
            WHERE e.event_type = 'transaction_start'
        ) AS transaction_starts,

        COUNT(*) FILTER (
            WHERE e.event_type = 'feature_used'
        ) AS features_used,

        COUNT(*) FILTER (
            WHERE e.event_type = 'transaction_failed'
        ) AS failed_transactions

    FROM users u

    LEFT JOIN product_events e
        ON e.user_id = u.user_id
        AND e.event_timestamp >= u.signup_date
        AND e.event_timestamp < u.signup_date + INTERVAL '30 days'

    GROUP BY u.user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON t.user_id = u.user_id

    WHERE t.status = 'Successful'
      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'
      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
)

SELECT

    CASE
        WHEN r.user_id IS NOT NULL
            THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END AS user_group,

    COUNT(*) AS users,

    ROUND(AVG(app_opens), 2)
        AS avg_app_opens,

    ROUND(AVG(product_views), 2)
        AS avg_product_views,

    ROUND(AVG(product_clicks), 2)
        AS avg_product_clicks,

    ROUND(AVG(transaction_starts), 2)
        AS avg_transaction_starts,

    ROUND(AVG(features_used), 2)
        AS avg_features_used,

    ROUND(AVG(failed_transactions), 2)
        AS avg_failed_transactions

FROM user_behavior b

LEFT JOIN month_1_retention r
    ON b.user_id = r.user_id

GROUP BY
    CASE
        WHEN r.user_id IS NOT NULL
            THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END

ORDER BY
    user_group;


-- ============================================
-- Product Adoption vs Month-1 Retention  27
-- ============================================

WITH product_users AS (

    SELECT DISTINCT
        u.user_id,
        t.product_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'
      AND t.transaction_date >= u.signup_date
      AND t.transaction_date < u.signup_date + INTERVAL '30 days'
),

month_1_retained AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'
      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'
      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
)

SELECT
    p.product_name,

    COUNT(DISTINCT pu.user_id) AS users,

    COUNT(DISTINCT mr.user_id) AS month_1_retained_users,

    ROUND(
        100.0 * COUNT(DISTINCT mr.user_id)
        / COUNT(DISTINCT pu.user_id),
        2
    ) AS month_1_retention_rate

FROM product_users pu

JOIN products p
    ON pu.product_id = p.product_id

LEFT JOIN month_1_retained mr
    ON pu.user_id = mr.user_id

GROUP BY
    p.product_name

ORDER BY
    month_1_retention_rate DESC;
-- ============================================
-- Product Adoption vs Retention Opportunity -- STEP 28
-- ============================================

WITH product_adoption AS (

    SELECT
        t.product_id,
        COUNT(DISTINCT t.user_id) AS users
    FROM transactions t
    WHERE t.status = 'Successful'
    GROUP BY t.product_id
),

total_users AS (

    SELECT COUNT(*) AS total_users
    FROM users
),

product_retention AS (

    SELECT
        t.product_id,

        COUNT(DISTINCT t.user_id) AS product_users,

        COUNT(DISTINCT CASE
            WHEN t2.user_id IS NOT NULL
            THEN t.user_id
        END) AS retained_users

    FROM transactions t

    JOIN users u
        ON t.user_id = u.user_id

    LEFT JOIN transactions t2
        ON t.user_id = t2.user_id
        AND t2.status = 'Successful'
        AND t2.transaction_date >=
            u.signup_date + INTERVAL '1 month'
        AND t2.transaction_date <
            u.signup_date + INTERVAL '2 months'

    WHERE t.status = 'Successful'
      AND t.transaction_date >= u.signup_date
      AND t.transaction_date <
          u.signup_date + INTERVAL '30 days'

    GROUP BY t.product_id
)

SELECT
    p.product_name,

    ROUND(
        100.0 * pa.users / tu.total_users,
        2
    ) AS adoption_rate,

    ROUND(
        100.0 * pr.retained_users / pr.product_users,
        2
    ) AS month_1_retention_rate

FROM product_adoption pa

JOIN product_retention pr
    ON pa.product_id = pr.product_id

JOIN products p
    ON pa.product_id = p.product_id

CROSS JOIN total_users tu

ORDER BY
    month_1_retention_rate DESC;

-- ============================================
-- Behavioral Drivers of Month-1 Retention -- STEP 29
-- ============================================

WITH user_behavior AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'app_open'
        ) AS app_opens,

        COUNT(*) FILTER (
            WHERE event_type = 'product_click'
        ) AS product_clicks,

        COUNT(*) FILTER (
            WHERE event_type = 'transaction_start'
        ) AS transaction_starts,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS features_used

    FROM product_events

    GROUP BY user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'

      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'

      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
)

SELECT

    CASE
        WHEN r.user_id IS NOT NULL
            THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END AS user_group,

    COUNT(*) AS users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE COALESCE(b.app_opens, 0) > 0
        ) / COUNT(*),
        2
    ) AS app_open_users_pct,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE COALESCE(b.product_clicks, 0) > 0
        ) / COUNT(*),
        2
    ) AS product_click_users_pct,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE COALESCE(b.transaction_starts, 0) > 0
        ) / COUNT(*),
        2
    ) AS transaction_start_users_pct,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE COALESCE(b.features_used, 0) > 0
        ) / COUNT(*),
        2
    ) AS feature_users_pct

FROM users u

LEFT JOIN user_behavior b
    ON u.user_id = b.user_id

LEFT JOIN month_1_retention r
    ON u.user_id = r.user_id

GROUP BY
    CASE
        WHEN r.user_id IS NOT NULL
            THEN 'Month-1 Retained'
        ELSE 'Not Retained'
    END

ORDER BY
    user_group;

-- ============================================
-- STEP 30
-- Feature Usage Level vs Month-1 Retention
-- ============================================

WITH feature_usage AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS feature_uses

    FROM product_events

    GROUP BY user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'

      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'

      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
),

grouped_users AS (

    SELECT
        u.user_id,

        CASE
            WHEN COALESCE(f.feature_uses, 0) = 0
                THEN '0 uses'

            WHEN f.feature_uses = 1
                THEN '1 use'

            WHEN f.feature_uses = 2
                THEN '2 uses'

            ELSE '3+ uses'
        END AS feature_usage_group,

        CASE
            WHEN m.user_id IS NOT NULL
                THEN 1
            ELSE 0
        END AS retained

    FROM users u

    LEFT JOIN feature_usage f
        ON u.user_id = f.user_id

    LEFT JOIN month_1_retention m
        ON u.user_id = m.user_id
)

SELECT
    feature_usage_group,

    COUNT(*) AS users,

    SUM(retained) AS month_1_retained_users,

    ROUND(
        100.0 * SUM(retained) / COUNT(*),
        2
    ) AS month_1_retention_rate

FROM grouped_users

GROUP BY feature_usage_group

ORDER BY
    CASE feature_usage_group
        WHEN '0 uses' THEN 1
        WHEN '1 use' THEN 2
        WHEN '2 uses' THEN 3
        WHEN '3+ uses' THEN 4
    END;

-- ============================================
-- STEP 31
-- Feature Engagement Retention Opportunity
-- ============================================

WITH feature_usage AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS feature_uses

    FROM product_events

    GROUP BY user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'

      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'

      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
),

grouped_users AS (

    SELECT
        u.user_id,

        CASE
            WHEN COALESCE(f.feature_uses, 0) = 0
                THEN '0 uses'
            WHEN f.feature_uses = 1
                THEN '1 use'
            WHEN f.feature_uses = 2
                THEN '2 uses'
            ELSE '3+ uses'
        END AS feature_usage_group,

        CASE
            WHEN m.user_id IS NOT NULL
                THEN 1
            ELSE 0
        END AS retained

    FROM users u

    LEFT JOIN feature_usage f
        ON u.user_id = f.user_id

    LEFT JOIN month_1_retention m
        ON u.user_id = m.user_id
),

group_rates AS (

    SELECT
        feature_usage_group,
        COUNT(*) AS users,
        SUM(retained) AS current_retained_users,

        ROUND(
            100.0 * SUM(retained) / COUNT(*),
            2
        ) AS current_retention_rate

    FROM grouped_users

    GROUP BY feature_usage_group
),

benchmark AS (

    SELECT
        current_retention_rate AS benchmark_rate

    FROM group_rates

    WHERE feature_usage_group = '3+ uses'
)

SELECT
    g.feature_usage_group,
    g.users,
    g.current_retained_users,
    g.current_retention_rate,

    b.benchmark_rate,

    ROUND(
        g.users * b.benchmark_rate / 100.0
    ) AS expected_retained_users,

    ROUND(
        g.users * b.benchmark_rate / 100.0
        - g.current_retained_users
    ) AS potential_incremental_retained_users

FROM group_rates g

CROSS JOIN benchmark b

ORDER BY
    CASE g.feature_usage_group
        WHEN '0 uses' THEN 1
        WHEN '1 use' THEN 2
        WHEN '2 uses' THEN 3
        WHEN '3+ uses' THEN 4
    END;

-- ============================================
-- STEP 32
-- Low Feature Engagement by Acquisition Channel
-- ============================================

WITH feature_usage AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS feature_uses

    FROM product_events

    GROUP BY user_id
)

SELECT
    u.acquisition_channel,

    COUNT(*) AS users,

    COUNT(*) FILTER (
        WHERE COALESCE(f.feature_uses, 0) = 0
    ) AS zero_use_users,

    COUNT(*) FILTER (
        WHERE COALESCE(f.feature_uses, 0) <= 2
    ) AS low_engagement_users,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE COALESCE(f.feature_uses, 0) <= 2
        )
        / COUNT(*),
        2
    ) AS low_engagement_rate

FROM users u

LEFT JOIN feature_usage f
    ON u.user_id = f.user_id

GROUP BY
    u.acquisition_channel

ORDER BY
    low_engagement_users DESC;

-- ============================================
-- STEP 33
-- Low Feature Engagement Retention by Channel
-- ============================================

WITH feature_usage AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS feature_uses

    FROM product_events

    GROUP BY user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'

      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'

      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
),

user_segments AS (

    SELECT
        u.user_id,
        u.acquisition_channel,

        CASE
            WHEN COALESCE(f.feature_uses, 0) = 0
                THEN '0 uses'

            WHEN f.feature_uses = 1
                THEN '1 use'

            WHEN f.feature_uses = 2
                THEN '2 uses'

            ELSE '3+ uses'
        END AS feature_usage_group,

        CASE
            WHEN m.user_id IS NOT NULL
                THEN 1
            ELSE 0
        END AS retained

    FROM users u

    LEFT JOIN feature_usage f
        ON u.user_id = f.user_id

    LEFT JOIN month_1_retention m
        ON u.user_id = m.user_id
)

SELECT
    acquisition_channel,
    feature_usage_group,
    COUNT(*) AS users,

    SUM(retained) AS retained_users,

    ROUND(
        100.0 * SUM(retained) / COUNT(*),
        2
    ) AS retention_rate

FROM user_segments

WHERE feature_usage_group IN (
    '0 uses',
    '1 use',
    '2 uses'
)

GROUP BY
    acquisition_channel,
    feature_usage_group

ORDER BY
    acquisition_channel,
    retention_rate;

-- ============================================
-- STEP 34
-- Retention Opportunity by Acquisition Channel
-- ============================================

WITH feature_usage AS (

    SELECT
        user_id,

        COUNT(*) FILTER (
            WHERE event_type = 'feature_used'
        ) AS feature_uses

    FROM product_events

    GROUP BY user_id
),

month_1_retention AS (

    SELECT DISTINCT
        u.user_id

    FROM users u

    JOIN transactions t
        ON u.user_id = t.user_id

    WHERE t.status = 'Successful'

      AND t.transaction_date >=
          u.signup_date + INTERVAL '1 month'

      AND t.transaction_date <
          u.signup_date + INTERVAL '2 months'
),

user_segments AS (

    SELECT
        u.user_id,
        u.acquisition_channel,

        CASE
            WHEN COALESCE(f.feature_uses, 0) <= 2
                THEN 1
            ELSE 0
        END AS low_engagement,

        CASE
            WHEN m.user_id IS NOT NULL
                THEN 1
            ELSE 0
        END AS retained

    FROM users u

    LEFT JOIN feature_usage f
        ON u.user_id = f.user_id

    LEFT JOIN month_1_retention m
        ON u.user_id = m.user_id
)

SELECT
    acquisition_channel,

    COUNT(*) FILTER (
        WHERE low_engagement = 1
    ) AS low_engagement_users,

    SUM(retained) FILTER (
        WHERE low_engagement = 1
    ) AS current_retained_users,

    ROUND(
        100.0 *
        SUM(retained) FILTER (
            WHERE low_engagement = 1
        )
        /
        COUNT(*) FILTER (
            WHERE low_engagement = 1
        ),
        2
    ) AS current_retention_rate,

    61.66 AS benchmark_retention_rate,

    ROUND(
        COUNT(*) FILTER (
            WHERE low_engagement = 1
        ) * 0.6166
    ) AS expected_retained_users,

    ROUND(
        COUNT(*) FILTER (
            WHERE low_engagement = 1
        ) * 0.6166
        -
        SUM(retained) FILTER (
            WHERE low_engagement = 1
        )
    ) AS potential_incremental_users

FROM user_segments

GROUP BY acquisition_channel

ORDER BY potential_incremental_users DESC;

-- ============================================
-- STEP 35 Feature-level check Its Result will Not be applicable with the current schema.
-- ============================================

SELECT
    event_type,
    COUNT(*) AS events
FROM product_events
GROUP BY event_type
ORDER BY events DESC;

