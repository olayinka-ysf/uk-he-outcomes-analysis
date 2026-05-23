-- Graduate employment outcomes by subject: full-time employment rate as salary/career outcome proxy
-- Salary band distribution by demographic available in hesa_grad_salary_bands
USE HE_Outcomes_Analysis;

WITH subject_employment AS (
    SELECT
        subject_area_of_degree,
        MAX(CASE WHEN activity = 'Full-time employment'
            THEN CAST(REPLACE([percent], '%', '') AS FLOAT) END) AS pct_ft_employed,
        MAX(CASE WHEN activity = 'Total with known outcomes' THEN number END) AS total_graduates
    FROM hesa_grad_outcomes_subject
    WHERE country_of_provider = 'All'
      AND provider_type = 'All'
      AND level_of_qualification_obtained = 'All'
      AND mode_of_former_study = 'All'
      AND interim_study = 'Exclude significant interim study'
      AND academic_year = '2022/23'
      AND subject_area_of_degree NOT LIKE 'Total%'
      AND subject_area_of_degree NOT LIKE 'All%'
    GROUP BY subject_area_of_degree
),
ranked_subjects AS (
    SELECT
        subject_area_of_degree,
        ROUND(pct_ft_employed, 1) AS pct_ft_employed,
        total_graduates,
        RANK()   OVER (ORDER BY pct_ft_employed DESC) AS ft_employment_rank,
        NTILE(4) OVER (ORDER BY pct_ft_employed DESC) AS quartile
    FROM subject_employment
    WHERE pct_ft_employed IS NOT NULL
)
SELECT
    ft_employment_rank,
    subject_area_of_degree,
    pct_ft_employed,
    total_graduates,
    CASE quartile
        WHEN 1 THEN 'Top quartile'
        WHEN 2 THEN 'Upper-middle quartile'
        WHEN 3 THEN 'Lower-middle quartile'
        WHEN 4 THEN 'Bottom quartile'
    END AS employment_quartile,
    CASE
        WHEN pct_ft_employed >= 70 THEN 'Strong career outcomes'
        WHEN pct_ft_employed >= 55 THEN 'Moderate career outcomes'
        ELSE 'Lower career outcomes'
    END AS outcome_rating
FROM ranked_subjects
ORDER BY ft_employment_rank;
