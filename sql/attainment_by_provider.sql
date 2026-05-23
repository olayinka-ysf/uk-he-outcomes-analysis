-- Degree attainment rates by provider, ranked using window functions (OfS AP provider-level data)
USE HE_Outcomes_Analysis;

WITH provider_attainment AS (
    SELECT
        ukprn,
        provider_name,
        indicator_value AS good_honours_rate,
        denominator AS total_qualifiers,
        numerator AS good_honours_count
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
ranked AS (
    SELECT
        ukprn,
        provider_name,
        ROUND(good_honours_rate, 1) AS good_honours_rate,
        total_qualifiers,
        good_honours_count,
        RANK()       OVER (ORDER BY good_honours_rate DESC) AS rank_highest,
        NTILE(5)     OVER (ORDER BY good_honours_rate DESC) AS quintile_band,
        AVG(good_honours_rate) OVER () AS sector_average,
        good_honours_rate - AVG(good_honours_rate) OVER () AS deviation_from_avg,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY good_honours_rate) OVER () AS sector_median
    FROM provider_attainment
)
SELECT
    rank_highest,
    provider_name,
    good_honours_rate,
    ROUND(sector_average, 1) AS sector_average,
    ROUND(sector_median, 1) AS sector_median,
    ROUND(deviation_from_avg, 1) AS deviation_from_avg,
    CASE quintile_band
        WHEN 1 THEN 'Top 20%'
        WHEN 2 THEN 'Upper middle 20%'
        WHEN 3 THEN 'Middle 20%'
        WHEN 4 THEN 'Lower middle 20%'
        WHEN 5 THEN 'Bottom 20%'
    END AS performance_band,
    total_qualifiers
FROM ranked
ORDER BY rank_highest;
