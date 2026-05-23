-- Year-over-year changes in widening participation indicators (FSM and ethnicity)
USE HE_Outcomes_Analysis;

WITH fsm_trend AS (
    SELECT
        time_period,
        MAX(CASE WHEN fsm_status = 'Free School Meals'  THEN progression_rate END) AS fsm_rate,
        MAX(CASE WHEN fsm_status = 'All Other Pupils'   THEN progression_rate END) AS non_fsm_rate,
        MAX(CASE WHEN fsm_status = 'Free School Meals'  THEN progression_rate END) -
        MIN(CASE WHEN fsm_status = 'All Other Pupils'   THEN progression_rate END) AS gap_pp
    FROM dfe_fsm
    WHERE geographic_level = 'National'
      AND country_name = 'England'
      AND fsm_status IN ('Free School Meals', 'All Other Pupils')
      AND time_period >= 201011
    GROUP BY time_period
),
fsm_yoy AS (
    SELECT
        time_period,
        fsm_rate,
        non_fsm_rate,
        gap_pp,
        LAG(fsm_rate)  OVER (ORDER BY time_period) AS prev_fsm_rate,
        LAG(gap_pp)    OVER (ORDER BY time_period) AS prev_gap,
        ROUND(fsm_rate - LAG(fsm_rate) OVER (ORDER BY time_period), 1) AS fsm_yoy_change,
        ROUND(gap_pp   - LAG(gap_pp)   OVER (ORDER BY time_period), 1) AS gap_yoy_change
    FROM fsm_trend
),
ethnicity_major_trend AS (
    SELECT
        time_period,
        ethnicity_major,
        ROUND(AVG(progression_rate), 1) AS avg_progression_rate
    FROM dfe_ethnicity
    WHERE geographic_level = 'National'
      AND country_name = 'England'
      AND ethnicity_major NOT IN ('Total')
      AND time_period >= 201415
    GROUP BY time_period, ethnicity_major
),
ethnicity_yoy AS (
    SELECT
        time_period,
        ethnicity_major,
        avg_progression_rate,
        LAG(avg_progression_rate) OVER (PARTITION BY ethnicity_major ORDER BY time_period) AS prev_rate,
        ROUND(
            avg_progression_rate -
            LAG(avg_progression_rate) OVER (PARTITION BY ethnicity_major ORDER BY time_period),
        1) AS yoy_change
    FROM ethnicity_major_trend
)
SELECT
    'FSM Gap Trend' AS series,
    CAST(time_period AS VARCHAR) AS year_code,
    CAST(gap_pp AS VARCHAR) AS metric_value,
    CAST(gap_yoy_change AS VARCHAR) AS yoy_change,
    CASE
        WHEN gap_yoy_change < 0 THEN 'Improving (gap narrowing)'
        WHEN gap_yoy_change > 0 THEN 'Worsening (gap widening)'
        ELSE 'No change'
    END AS direction
FROM fsm_yoy
WHERE time_period IS NOT NULL

UNION ALL

SELECT
    'Ethnicity: ' + ethnicity_major,
    CAST(time_period AS VARCHAR),
    CAST(avg_progression_rate AS VARCHAR),
    CAST(yoy_change AS VARCHAR),
    CASE
        WHEN yoy_change > 0  THEN 'Improving'
        WHEN yoy_change < 0  THEN 'Declining'
        ELSE 'Stable'
    END
FROM ethnicity_yoy
WHERE yoy_change IS NOT NULL

ORDER BY series, year_code;
