-- Well integrity status
-- One row per well with a red / amber / green status. This is the query behind the dashboard overview. Red means a barrier has failed or pressure is above MAASP; amber means something needs attention soon.

-- Well integrity status (traffic light) per well
-- SQL Server: replace date(x, '+n months') with DATEADD(month, n, x)
--             and date(x, '-90 days') with DATEADD(day, -90, x)
WITH s AS (
  SELECT as_of_date FROM report_settings
),
latest_test AS (
  SELECT t.element_id, t.test_date, t.result,
         ROW_NUMBER() OVER (PARTITION BY t.element_id ORDER BY t.test_date DESC) AS rn
  FROM integrity_test t
),
element_state AS (
  SELECT e.well_id,
         SUM(CASE WHEN lt.result = 'FAIL' THEN 1 ELSE 0 END) AS failed_elements,
         SUM(CASE WHEN lt.test_date IS NULL
                    OR date(lt.test_date, '+' || et.test_interval_months || ' months') < s.as_of_date
                  THEN 1 ELSE 0 END) AS overdue_elements
  FROM barrier_element e
  JOIN element_type et ON et.element_type_id = e.element_type_id
  LEFT JOIN latest_test lt ON lt.element_id = e.element_id AND lt.rn = 1
  CROSS JOIN s
  GROUP BY e.well_id
),
pressure_state AS (
  SELECT a.well_id, MAX(1.0 * r.pressure_bar / a.maasp_bar) AS max_ratio
  FROM annulus a
  JOIN annulus_reading r ON r.annulus_id = a.annulus_id
  CROSS JOIN s
  WHERE r.reading_date > date(s.as_of_date, '-90 days')
  GROUP BY a.well_id
),
issue_state AS (
  SELECT well_id,
         SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END)  AS open_high,
         SUM(CASE WHEN severity <> 'High' THEN 1 ELSE 0 END) AS open_other
  FROM integrity_issue
  WHERE issue_status = 'Open'
  GROUP BY well_id
)
SELECT w.well_name,
       f.field_name,
       w.well_type,
       w.well_status,
       es.failed_elements,
       es.overdue_elements,
       ROUND(100.0 * ps.max_ratio, 0)  AS max_pct_maasp,
       COALESCE(i.open_high, 0) + COALESCE(i.open_other, 0) AS open_issues,
       CASE
         WHEN es.failed_elements > 0      THEN 'RED'
         WHEN ps.max_ratio > 1.0          THEN 'RED'
         WHEN COALESCE(i.open_high, 0) > 0 THEN 'RED'
         WHEN es.overdue_elements > 0     THEN 'AMBER'
         WHEN ps.max_ratio >= 0.8         THEN 'AMBER'
         WHEN COALESCE(i.open_other, 0) > 0 THEN 'AMBER'
         ELSE 'GREEN'
       END AS integrity_status,
       CASE
         WHEN es.failed_elements > 0      THEN 'Failed barrier test'
         WHEN ps.max_ratio > 1.0          THEN 'Annulus pressure above MAASP'
         WHEN COALESCE(i.open_high, 0) > 0 THEN 'Open high-severity issue'
         WHEN es.overdue_elements > 0     THEN 'Barrier test overdue'
         WHEN ps.max_ratio >= 0.8         THEN 'Annulus pressure at 80% of MAASP or more'
         WHEN COALESCE(i.open_other, 0) > 0 THEN 'Open medium-severity issue'
         ELSE 'All checks passed'
       END AS main_reason
FROM well w
JOIN field f                ON f.field_id = w.field_id
LEFT JOIN element_state es  ON es.well_id = w.well_id
LEFT JOIN pressure_state ps ON ps.well_id = w.well_id
LEFT JOIN issue_state i     ON i.well_id  = w.well_id
ORDER BY CASE integrity_status WHEN 'RED' THEN 1 WHEN 'AMBER' THEN 2 ELSE 3 END,
         w.well_name;
