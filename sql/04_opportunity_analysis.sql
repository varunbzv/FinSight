-- ============================================
-- FinSight - Product Opportunity Analysis
-- ============================================

-- Insurance opportunity using
-- Bill Payments as benchmark

SELECT
    35485 AS insurance_viewers,

    17124 AS current_successful_users,

    52.30 AS benchmark_conversion_pct,

    ROUND(
        35485 * 52.30 / 100.0
    ) AS expected_successful_users,

    ROUND(
        (35485 * 52.30 / 100.0) - 17124
    ) AS potential_incremental_users;



    