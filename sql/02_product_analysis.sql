-- ============================================
-- FinSight - Product Analysis
-- ============================================

-- Product financial performance

SELECT
    p.product_id,
    p.product_name,
    p.product_category,

    COUNT(t.transaction_id) AS total_transactions,

    COUNT(t.transaction_id) FILTER (
        WHERE t.status = 'Successful'
    ) AS successful_transactions,

    ROUND(
        100.0 *
        COUNT(t.transaction_id) FILTER (
            WHERE t.status = 'Successful'
        ) / NULLIF(COUNT(t.transaction_id), 0),
        2
    ) AS success_rate,

    ROUND(
        SUM(t.amount) FILTER (
            WHERE t.status = 'Successful'
        ),
        2
    ) AS successful_transaction_value,

    ROUND(
        AVG(t.amount) FILTER (
            WHERE t.status = 'Successful'
        ),
        2
    ) AS avg_transaction_value

FROM products p

LEFT JOIN transactions t
    ON p.product_id = t.product_id

GROUP BY
    p.product_id,
    p.product_name,
    p.product_category

ORDER BY successful_transaction_value DESC;


-- Product adoption

SELECT
    p.product_id,
    p.product_name,

    COUNT(DISTINCT t.user_id) AS unique_users,

    ROUND(
        100.0 * COUNT(DISTINCT t.user_id)
        / (SELECT COUNT(*) FROM users),
        2
    ) AS adoption_rate,

    COUNT(t.transaction_id) AS total_transactions,

    ROUND(
        COUNT(t.transaction_id)::NUMERIC
        / NULLIF(COUNT(DISTINCT t.user_id), 0),
        2
    ) AS transactions_per_user,

    ROUND(
        SUM(t.amount) FILTER (
            WHERE t.status = 'Successful'
        )
        / NULLIF(COUNT(DISTINCT t.user_id), 0),
        2
    ) AS successful_value_per_user

FROM products p

LEFT JOIN transactions t
    ON p.product_id = t.product_id

GROUP BY
    p.product_id,
    p.product_name

ORDER BY adoption_rate DESC;


