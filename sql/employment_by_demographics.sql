-- Graduate employment rates by ethnicity, sex, and disability (OfS AP Progression data)
USE HE_Outcomes_Analysis;

WITH ethnicity_employment AS (
    SELECT
        'Ethnicity' AS demographic_dimension,
        split_ind1 AS group_label,
        indicator_value AS employment_rate,
        denominator AS total_graduates
    FROM ap_sector
    WHERE lifecycle_stage = 'Progression'
      AND split_ind_type = 'Ethnicity'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
      AND split_ind_combination IN ('White', 'Asian', 'Black', 'Mixed', 'Other')
),
sex_employment AS (
    SELECT
        'Sex' AS demographic_dimension,
        split_ind1 AS group_label,
        indicator_value AS employment_rate,
        denominator AS total_graduates
    FROM ap_sector
    WHERE lifecycle_stage = 'Progression'
      AND split_ind_type = 'Sex'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
      AND split_ind_combination IN ('Female', 'Male')
),
disability_employment AS (
    SELECT
        'Disability' AS demographic_dimension,
        split_ind1 AS group_label,
        indicator_value AS employment_rate,
        denominator AS total_graduates
    FROM ap_sector
    WHERE lifecycle_stage = 'Progression'
      AND split_ind_type = 'Disability'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
      AND split_ind_combination IN ('Disabled', 'NoKnownDisability')
),
combined AS (
    SELECT * FROM ethnicity_employment
    UNION ALL
    SELECT * FROM sex_employment
    UNION ALL
    SELECT * FROM disability_employment
),
with_rank AS (
    SELECT
        demographic_dimension,
        group_label,
        ROUND(employment_rate, 1) AS employment_rate,
        total_graduates,
        AVG(employment_rate) OVER (PARTITION BY demographic_dimension) AS dimension_average,
        RANK() OVER (PARTITION BY demographic_dimension ORDER BY employment_rate DESC) AS rank_within_dimension,
        employment_rate - AVG(employment_rate) OVER (PARTITION BY demographic_dimension) AS deviation_from_avg
    FROM combined
)
SELECT
    demographic_dimension,
    group_label,
    employment_rate,
    ROUND(dimension_average, 1) AS dimension_average,
    ROUND(deviation_from_avg, 1) AS deviation_from_avg,
    rank_within_dimension,
    CASE
        WHEN deviation_from_avg >= 2  THEN 'Above average'
        WHEN deviation_from_avg <= -2 THEN 'Below average'
        ELSE 'Near average'
    END AS performance_vs_dimension
FROM with_rank
ORDER BY demographic_dimension, employment_rate DESC;
