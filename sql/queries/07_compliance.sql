-- Test compliance by field
-- Share of barrier elements tested within their required interval, by field and element type. A typical monthly KPI.

-- Test compliance: elements tested within interval / all elements
WITH s AS (SELECT as_of_date FROM report_settings),
last_test AS (
  SELECT element_id, MAX(test_date) AS last_date
  FROM integrity_test
  GROUP BY element_id
)
SELECT f.field_name,
       et.element_name,
       COUNT(*) AS elements,
       SUM(CASE WHEN date(lt.last_date, '+' || et.test_interval_months || ' months') >= s.as_of_date
                THEN 1 ELSE 0 END) AS in_date,
       ROUND(100.0 * SUM(CASE WHEN date(lt.last_date, '+' || et.test_interval_months || ' months') >= s.as_of_date
                THEN 1 ELSE 0 END) / COUNT(*), 0) AS compliance_pct
FROM barrier_element e
JOIN well w          ON w.well_id = e.well_id
JOIN field f         ON f.field_id = w.field_id
JOIN element_type et ON et.element_type_id = e.element_type_id
LEFT JOIN last_test lt ON lt.element_id = e.element_id
CROSS JOIN s
GROUP BY f.field_name, et.element_name
ORDER BY f.field_name, compliance_pct, et.element_name;
