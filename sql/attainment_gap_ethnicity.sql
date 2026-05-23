-- Attainment gap by ethnicity: first/2:1 degree rates vs White students (OfS AP sector data)
USE HE_Outcomes_Analysis;

WITH ethnicity_attainment AS (
    SELECT
        split_ind1 AS ethnicity_code,
        indicator_value AS attainment_rate,
        denominator AS total_qualifiers,
        numerator AS good_honours
    FROM ap_sector
    WHERE lifecycle_stage = 'Attainment'
      AND split_ind_type = 'Ethnicity'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND level = 'First degree'
      AND type = 'Single'
      AND split_ind_combination IN ('White', 'Asian', 'Black', 'Mixed', 'Other')
),
white_rate AS (
    SELECT attainment_rate AS white_good_honours_rate
    FROM ethnicity_attainment
    WHERE ethnicity_code = 'White'
),
gaps AS (
    SELECT
        e.ethnicity_code,
        e.attainment_rate,
        e.total_qualifiers,
        e.good_honours,
        w.white_good_honours_rate,
        ROUND(w.white_good_honours_rate - e.attainment_rate, 1) AS gap_vs_white_pp,
        RANK() OVER (ORDER BY e.attainment_rate DESC) AS attainment_rank
    FROM ethnicity_attainment e
    CROSS JOIN white_rate w
)
SELECT
    ethnicity_code,
    ROUND(attainment_rate, 1) AS pct_good_honours,
    ROUND(white_good_honours_rate, 1) AS white_pct_good_honours,
    gap_vs_white_pp,
    CASE
        WHEN gap_vs_white_pp <= 0   THEN 'No gap (at or above White)'
        WHEN gap_vs_white_pp < 5    THEN 'Small gap (<5pp)'
        WHEN gap_vs_white_pp < 15   THEN 'Moderate gap (5-15pp)'
        ELSE 'Large gap (15pp+)'
    END AS gap_category,
    total_qualifiers,
    attainment_rank
FROM gaps
ORDER BY attainment_rank;
