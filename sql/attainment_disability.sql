-- Attainment gap between disabled and non-disabled students (OfS AP sector data)
USE HE_Outcomes_Analysis;

WITH disability_attainment AS (
    SELECT
        split_ind1 AS disability_status,
        indicator_value AS good_honours_rate,
        denominator AS total_qualifiers,
        numerator AS good_honours_count
    FROM ap_sector
    WHERE lifecycle_stage = 'Attainment'
      AND split_ind_type = 'Disability'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND level = 'First degree'
      AND type = 'Single'
      AND split_ind_combination IN ('Disabled', 'NoKnownDisability')
),
gap_calc AS (
    SELECT
        MAX(CASE WHEN disability_status = 'NoKnownDisability' THEN good_honours_rate END) AS non_disabled_rate,
        MAX(CASE WHEN disability_status = 'Disabled'          THEN good_honours_rate END) AS disabled_rate,
        MAX(CASE WHEN disability_status = 'NoKnownDisability' THEN good_honours_rate END) -
        MAX(CASE WHEN disability_status = 'Disabled'          THEN good_honours_rate END) AS attainment_gap_pp
    FROM disability_attainment
),
disability_types AS (
    SELECT
        split_ind1 AS disability_type,
        indicator_value AS good_honours_rate,
        denominator AS total_qualifiers
    FROM ap_sector
    WHERE lifecycle_stage = 'Attainment'
      AND split_ind_type = 'DisabilityType'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND level = 'First degree'
      AND type = 'Single'
      AND indicator_value IS NOT NULL
)
SELECT
    'Summary' AS result_type,
    'Non-disabled' AS group_label,
    ROUND(non_disabled_rate, 1) AS good_honours_pct,
    NULL AS total_qualifiers,
    ROUND(attainment_gap_pp, 1) AS gap_vs_non_disabled,
    CASE
        WHEN attainment_gap_pp < 5  THEN 'Small gap'
        WHEN attainment_gap_pp < 10 THEN 'Moderate gap'
        ELSE 'Large gap'
    END AS gap_severity
FROM gap_calc

UNION ALL

SELECT
    'Summary',
    'Disabled',
    ROUND(disabled_rate, 1),
    NULL,
    0.0,
    ''
FROM gap_calc

UNION ALL

SELECT
    'By disability type',
    disability_type,
    ROUND(good_honours_rate, 1),
    CAST(total_qualifiers AS INT),
    ROUND(non_disabled_rate - good_honours_rate, 1),
    CASE
        WHEN non_disabled_rate - good_honours_rate < 5   THEN 'Small gap'
        WHEN non_disabled_rate - good_honours_rate < 10  THEN 'Moderate gap'
        ELSE 'Large gap'
    END
FROM disability_types
CROSS JOIN gap_calc
ORDER BY result_type DESC, good_honours_pct DESC;
