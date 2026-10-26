-- Barrier elements needing action
-- Elements whose latest test failed or whose next test is past due, with days overdue. This is the work list for the well integrity engineer.

-- Barrier elements with a failed latest test or an overdue test
-- SQL Server: DATEDIFF(day, due_date, as_of_date) instead of julianday()
WITH s AS (SELECT as_of_date FROM report_settings),
latest_test AS (
  SELECT t.*, ROW_NUMBER() OVER (PARTITION BY t.element_id ORDER BY t.test_date DESC) AS rn
  FROM integrity_test t
)
SELECT w.well_name,
       e.envelope,
       et.element_name,
       lt.test_date AS last_test,
       lt.result    AS last_result,
       date(lt.test_date, '+' || et.test_interval_months || ' months') AS next_due,
       CASE WHEN lt.result = 'FAIL' THEN 'Failed test'
            ELSE 'Overdue ' || CAST(julianday(s.as_of_date)
                 - julianday(date(lt.test_date, '+' || et.test_interval_months || ' months')) AS INTEGER) || ' days'
       END AS action_reason
FROM barrier_element e
JOIN well w          ON w.well_id = e.well_id
JOIN element_type et ON et.element_type_id = e.element_type_id
JOIN latest_test lt  ON lt.element_id = e.element_id AND lt.rn = 1
CROSS JOIN s
WHERE lt.result = 'FAIL'
   OR date(lt.test_date, '+' || et.test_interval_months || ' months') < s.as_of_date
ORDER BY CASE WHEN lt.result = 'FAIL' THEN 0 ELSE 1 END, w.well_name;
