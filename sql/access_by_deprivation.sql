-- HE progression rates by deprivation (FSM status as deprivation proxy), with IMD gap from OfS AP data
USE HE_Outcomes_Analysis;

WITH fsm_national AS (
    SELECT
        time_period,
        fsm_status,
        progression_rate,
        number_of_he_students,
        number_of_students
    FROM dfe_fsm
    WHERE geographic_level = 'National'
      AND country_name = 'England'
      AND time_period >= 201415
),
latest_year AS (
    SELECT MAX(time_period) AS max_year FROM fsm_national
),
fsm_latest AS (
    SELECT
        f.fsm_status,
        f.progression_rate,
        f.number_of_he_students,
        f.number_of_students,
        RANK() OVER (ORDER BY f.progression_rate DESC) AS rate_rank
    FROM fsm_national f
    INNER JOIN latest_year l ON f.time_period = l.max_year
    WHERE f.fsm_status IN ('Free School Meals', 'All Other Pupils')
),
gap_over_time AS (
    SELECT
        time_period,
        MAX(CASE WHEN fsm_status = 'All Other Pupils' THEN progression_rate END) AS non_fsm_rate,
        MAX(CASE WHEN fsm_status = 'Free School Meals' THEN progression_rate END) AS fsm_rate,
        MAX(CASE WHEN fsm_status = 'All Other Pupils' THEN progression_rate END) -
        MAX(CASE WHEN fsm_status = 'Free School Meals' THEN progression_rate END) AS gap_pp,
        LAG(
            MAX(CASE WHEN fsm_status = 'All Other Pupils' THEN progression_rate END) -
            MAX(CASE WHEN fsm_status = 'Free School Meals' THEN progression_rate END)
        ) OVER (ORDER BY time_period) AS prev_year_gap
    FROM fsm_national
    WHERE fsm_status IN ('Free School Meals', 'All Other Pupils')
    GROUP BY time_period
),
imd_gap AS (
    SELECT
        split_ind1 AS imd_quintile,
        indicator_value AS access_rate,
        CASE split_ind1
            WHEN 'IMDQ1' THEN 1
            WHEN 'IMDQ2' THEN 2
            WHEN 'IMDQ3' THEN 3
            WHEN 'IMDQ4' THEN 4
            WHEN 'IMDQ5' THEN 5
        END AS sort_order,
        CASE split_ind1
            WHEN 'IMDQ1' THEN 'Q1 - Most deprived'
            WHEN 'IMDQ2' THEN 'Q2'
            WHEN 'IMDQ3' THEN 'Q3'
            WHEN 'IMDQ4' THEN 'Q4'
            WHEN 'IMDQ5' THEN 'Q5 - Least deprived'
        END AS quintile_label
    FROM ap_sector
    WHERE lifecycle_stage = 'Access'
      AND split_ind_type = 'EnglishIMDQuintile_2019'
      AND year_timeseries = 'AGGLAST2YRS'
      AND mode = 'Full-time'
      AND level = 'All undergraduates'
      AND type = 'Single'
      AND split_ind_combination IN ('IMDQ1', 'IMDQ2', 'IMDQ3', 'IMDQ4', 'IMDQ5')
)
SELECT
    'FSM gap (most recent year)' AS analysis,
    CAST(non_fsm_rate AS VARCHAR) + '% vs ' + CAST(fsm_rate AS VARCHAR) + '%' AS rates,
    CAST(gap_pp AS VARCHAR) + ' pp gap' AS gap_summary,
    CASE WHEN gap_pp > ISNULL(prev_year_gap, gap_pp)
         THEN 'Widening' ELSE 'Narrowing or stable' END AS trend
FROM gap_over_time
WHERE time_period = (SELECT MAX(time_period) FROM gap_over_time)

UNION ALL

SELECT
    'IMD access rate: ' + quintile_label,
    CAST(access_rate AS VARCHAR) + '%',
    CAST(
        access_rate - FIRST_VALUE(access_rate) OVER (ORDER BY sort_order)
    AS VARCHAR) + ' pp vs Q1',
    ''
FROM imd_gap

ORDER BY analysis;
