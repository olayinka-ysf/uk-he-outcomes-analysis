-- Provider scorecard: access, attainment, and outcomes ranked across all three dimensions
USE HE_Outcomes_Analysis;

WITH provider_access AS (
    SELECT
        ukprn,
        provider_name,
        indicator_value AS access_rate
    FROM ap_providers
    WHERE lifecycle_stage = 'Access'
      AND split_ind_type = 'EnglishIMDQuintile_2019'
      AND split_ind_combination = 'IMDQ1'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND level = 'All undergraduates'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
      AND ukprn <> 'SECTOR'
),
provider_attainment AS (
    SELECT
        ukprn,
        indicator_value AS good_honours_rate
    FROM ap_providers
    WHERE lifecycle_stage = 'Attainment'
      AND split_ind_type = 'Overall'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND level = 'First degree'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
      AND ukprn <> 'SECTOR'
),
provider_progression AS (
    SELECT
        ukprn,
        indicator_value AS progression_rate
    FROM ap_providers
    WHERE lifecycle_stage = 'Progression'
      AND split_ind_type = 'Overall'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
      AND ukprn <> 'SECTOR'
),
combined AS (
    SELECT
        a.ukprn,
        a.provider_name,
        a.access_rate,
        t.good_honours_rate,
        p.progression_rate
    FROM provider_access a
    LEFT JOIN provider_attainment t ON a.ukprn = t.ukprn
    LEFT JOIN provider_progression p ON a.ukprn = p.ukprn
    WHERE t.good_honours_rate IS NOT NULL
      AND p.progression_rate IS NOT NULL
),
ranked AS (
    SELECT
        ukprn,
        provider_name,
        ROUND(access_rate, 1)       AS access_rate_pct,
        ROUND(good_honours_rate, 1) AS good_honours_pct,
        ROUND(progression_rate, 1)  AS progression_pct,
        RANK() OVER (ORDER BY access_rate DESC)       AS access_rank,
        RANK() OVER (ORDER BY good_honours_rate DESC) AS attainment_rank,
        RANK() OVER (ORDER BY progression_rate DESC)  AS progression_rank,
        COUNT(*) OVER () AS total_providers
    FROM combined
)
SELECT
    provider_name,
    access_rate_pct,
    good_honours_pct,
    progression_pct,
    access_rank,
    attainment_rank,
    progression_rank,
    ROUND((CAST(access_rank AS FLOAT) + attainment_rank + progression_rank) / 3.0, 1) AS avg_rank,
    RANK() OVER (
        ORDER BY (CAST(access_rank AS FLOAT) + attainment_rank + progression_rank) / 3.0 ASC
    ) AS overall_rank,
    total_providers,
    CASE
        WHEN (CAST(access_rank AS FLOAT) + attainment_rank + progression_rank) / 3.0
             <= total_providers * 0.2 THEN 'Top 20%'
        WHEN (CAST(access_rank AS FLOAT) + attainment_rank + progression_rank) / 3.0
             <= total_providers * 0.4 THEN 'Top 40%'
        WHEN (CAST(access_rank AS FLOAT) + attainment_rank + progression_rank) / 3.0
             <= total_providers * 0.6 THEN 'Middle'
        WHEN (CAST(access_rank AS FLOAT) + attainment_rank + progression_rank) / 3.0
             <= total_providers * 0.8 THEN 'Lower 40%'
        ELSE 'Bottom 20%'
    END AS overall_band
FROM ranked
ORDER BY overall_rank;
