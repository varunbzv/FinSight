-- ============================================
-- FinSight - Executive Metrics
-- ============================================

-- User / onboarding metrics

SELECT
    COUNT(*) AS total_users,

    COUNT(*) FILTER (
        WHERE account_status = 'Active'
    ) AS active_users,

    COUNT(*) FILTER (
        WHERE kyc_status = 'Completed'
    ) AS kyc_completed_users,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE kyc_status = 'Completed'
        ) / COUNT(*),
        2
    ) AS kyc_completion_rate

FROM users;


-- Transaction metrics

SELECT
    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE status = 'Successful'
    ) AS successful_transactions,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE status = 'Successful'
        ) / COUNT(*),
        2
    ) AS transaction_success_rate,

    ROUND(
        SUM(amount) FILTER (
            WHERE status = 'Successful'
        ),
        2
    ) AS successful_transaction_value,

    ROUND(
        AVG(amount) FILTER (
            WHERE status = 'Successful'
        ),
        2
    ) AS average_successful_transaction_value

FROM transactions;
