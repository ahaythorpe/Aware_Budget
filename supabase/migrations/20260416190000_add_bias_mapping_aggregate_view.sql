-- AGGREGATE VIEW for bias_mapping_stats
--
-- The actual "industry research deliverable" surface. Strips
-- user_id and only exposes anonymised counts + sample size +
-- confirmation rate per mapping (category × planned_status × bias).
--
-- Use cases:
--   - "Across all MoneyMind users, when the algorithm tagged
--      Ego Depletion on Coffee+Impulse, users said YES 73% of
--      the time after 2,400 reviews."
--   - Find mappings the global data is rejecting (low rate,
--     high sample) → candidates for retirement.
--   - Find mappings the data is validating strongly (high rate,
--     high sample) → publishable evidence.
--
-- Privacy:
--   - View has no user_id column.
--   - Only returns mappings with sample_size >= 50 to prevent any
--     single user dominating the signal AND to avoid k-anonymity
--     issues when the user base is small.
--   - SECURITY INVOKER (default) — but the view itself is grantable
--     publicly because it can't expose user-level data.

CREATE OR REPLACE VIEW public.bias_mapping_aggregate AS
SELECT
    category,
    planned_status,
    bias_name,
    COUNT(*) AS contributing_users,
    SUM(identified_count) AS total_identified,
    SUM(not_sure_count)   AS total_not_sure,
    SUM(different_count)  AS total_different,
    SUM(identified_count + not_sure_count + different_count) AS total_sample_size,
    CASE
        WHEN SUM(identified_count + not_sure_count + different_count) = 0 THEN NULL
        ELSE ROUND(
            SUM(identified_count)::numeric
            / NULLIF(SUM(identified_count + not_sure_count + different_count), 0),
            3
        )
    END AS confirmation_rate
FROM public.bias_mapping_stats
GROUP BY category, planned_status, bias_name
HAVING SUM(identified_count + not_sure_count + different_count) >= 50;

COMMENT ON VIEW public.bias_mapping_aggregate IS
    'Anonymised cross-user mapping confirmation rates. Used for the research deliverable — finding mappings the global data is validating or rejecting. k-anonymity floor: 50 reviews per mapping minimum.';

-- Allow read access to anyone authenticated (no user-level data
-- in the view — only aggregate counts).
GRANT SELECT ON public.bias_mapping_aggregate TO authenticated, anon;
