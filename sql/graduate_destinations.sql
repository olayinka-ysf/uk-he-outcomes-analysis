-- Graduate destinations 15 months after finishing, by subject area (HESA Graduate Outcomes 2022/23)
USE HE_Outcomes_Analysis;

WITH subject_activity AS (
    SELECT
        subject_area_of_degree,
        activity,
        number,
        [percent],
        CAST(REPLACE([percent], '%', '') AS FLOAT) AS pct_numeric
    FROM hesa_grad_outcomes_subject
    WHERE country_of_provider = 'All'
      AND provider_type = 'All'
      AND level_of_qualification_obtained = 'All'
      AND mode_of_former_study = 'All'
      AND interim_study = 'Exclude significant interim study'
      AND academic_year = '2022/23'
      AND activity IN (
          'Full-time employment',
          'Part-time employment',
          'Full-time further study',
          'Part-time further study',
          'Unemployed',
          'Total with known outcomes'
      )
      AND subject_area_of_degree NOT LIKE 'Total%'
      AND subject_area_of_degree NOT LIKE 'All%'
),
pivoted AS (
    SELECT
        subject_area_of_degree,
        MAX(CASE WHEN activity = 'Full-time employment'   THEN pct_numeric END) AS pct_ft_employed,
        MAX(CASE WHEN activity = 'Part-time employment'   THEN pct_numeric END) AS pct_pt_employed,
        MAX(CASE WHEN activity = 'Full-time further study' THEN pct_numeric END) AS pct_ft_study,
        MAX(CASE WHEN activity = 'Part-time further study' THEN pct_numeric END) AS pct_pt_study,
        MAX(CASE WHEN activity = 'Unemployed'              THEN pct_numeric END) AS pct_unemployed,
        MAX(CASE WHEN activity = 'Total with known outcomes' THEN number END) AS total_known
    FROM subject_activity
    GROUP BY subject_area_of_degree
),
ranked AS (
    SELECT
        subject_area_of_degree,
        ROUND(ISNULL(pct_ft_employed, 0) + ISNULL(pct_pt_employed, 0), 1) AS pct_any_employment,
        ROUND(pct_ft_employed, 1) AS pct_ft_employed,
        ROUND(ISNULL(pct_ft_study, 0) + ISNULL(pct_pt_study, 0), 1) AS pct_any_study,
        ROUND(pct_unemployed, 1) AS pct_unemployed,
        total_known,
        RANK() OVER (ORDER BY ISNULL(pct_ft_employed, 0) + ISNULL(pct_pt_employed, 0) DESC) AS employment_rank,
        RANK() OVER (ORDER BY pct_unemployed ASC) AS lowest_unemployment_rank
    FROM pivoted
    WHERE total_known IS NOT NULL
)
SELECT
    employment_rank,
    subject_area_of_degree,
    pct_any_employment,
    pct_ft_employed,
    pct_any_study,
    pct_unemployed,
    total_known,
    CASE
        WHEN pct_any_employment >= 80 THEN 'High employment'
        WHEN pct_any_employment >= 65 THEN 'Moderate employment'
        ELSE 'Lower employment'
    END AS employment_band
FROM ranked
ORDER BY employment_rank;
