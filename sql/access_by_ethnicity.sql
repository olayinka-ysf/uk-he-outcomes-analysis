-- HE progression rates by ethnic group at national level (DfE Widening Participation data)
USE HE_Outcomes_Analysis;

WITH latest_year AS (
    SELECT MAX(time_period) AS max_year
    FROM dfe_ethnicity
    WHERE geographic_level = 'National'
      AND country_name = 'England'
),
ethnicity_rates AS (
    SELECT
        e.ethnicity_major,
        e.ethnicity_minor,
        e.progression_rate,
        e.high_tariff_progression_rate,
        e.number_of_he_students,
        e.number_of_students
    FROM dfe_ethnicity e
    INNER JOIN latest_year l ON e.time_period = l.max_year
    WHERE e.geographic_level = 'National'
      AND e.country_name = 'England'
      AND e.ethnicity_minor NOT IN ('Total', 'All ethnic groups')
      AND e.progression_rate IS NOT NULL
),
white_british_rate AS (
    SELECT progression_rate AS wb_rate
    FROM ethnicity_rates
    WHERE ethnicity_minor = 'English / Welsh / Scottish / Northern Irish / British'
),
ranked AS (
    SELECT
        e.ethnicity_major,
        e.ethnicity_minor,
        e.progression_rate,
        e.high_tariff_progression_rate,
        e.number_of_he_students,
        w.wb_rate AS white_british_rate,
        e.progression_rate - w.wb_rate AS gap_vs_white_british,
        RANK() OVER (ORDER BY e.progression_rate DESC) AS progression_rank,
        RANK() OVER (ORDER BY e.high_tariff_progression_rate DESC) AS high_tariff_rank
    FROM ethnicity_rates e
    CROSS JOIN white_british_rate w
)
SELECT
    ethnicity_major,
    ethnicity_minor,
    progression_rate,
    high_tariff_progression_rate,
    number_of_he_students,
    white_british_rate,
    ROUND(gap_vs_white_british, 1) AS gap_vs_white_british_pp,
    CASE
        WHEN gap_vs_white_british >= 5  THEN 'Above White British'
        WHEN gap_vs_white_british >= -5 THEN 'Similar to White British'
        ELSE 'Below White British'
    END AS relative_position,
    progression_rank,
    high_tariff_rank
FROM ranked
ORDER BY progression_rate DESC;
