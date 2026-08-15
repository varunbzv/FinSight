-- ============================================
-- FinSight - Product Funnel Analysis
-- ============================================

WITH funnel AS (

    SELECT
        product_id,

        COUNT(DISTINCT user_id) FILTER (
            WHERE event_type = 'product_view'
        ) AS viewers,

        COUNT(DISTINCT user_id) FILTER (
            WHERE event_type = 'product_click'
        ) AS clickers,

        COUNT(DISTINCT user_id) FILTER (
            WHERE event_type = 'transaction_start'
        ) AS starters,

        COUNT(DISTINCT user_id) FILTER (
            WHERE event_type = 'transaction_success'
        ) AS successful_users

    FROM product_events

    WHERE product_id IS NOT NULL

    GROUP BY product_id
)

SELECT
    p.product_name,

    f.viewers,
    f.clickers,
    f.starters,
    f.successful_users,

    ROUND(
        100.0 * f.clickers / NULLIF(f.viewers, 0),
        2
    ) AS view_to_click_pct,

    ROUND(
        100.0 * f.starters / NULLIF(f.clickers, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * f.successful_users / NULLIF(f.starters, 0),
        2
    ) AS start_to_success_pct,

    ROUND(
        100.0 * f.successful_users / NULLIF(f.viewers, 0),
        2
    ) AS overall_conversion_pct

FROM funnel f

JOIN products p
    ON p.product_id = f.product_id

ORDER BY overall_conversion_pct DESC;



