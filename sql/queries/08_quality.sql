-- Data quality checks
-- Finds gaps a database will not catch on its own: failed tests with no issue logged, missing gauge readings, and closed issues with no repair recorded.

-- Data quality checks
SELECT 'Failed test with no issue logged' AS check_name,
       w.well_name, et.element_name AS detail, t.test_date AS record_date
FROM integrity_test t
JOIN barrier_element e ON e.element_id = t.element_id
JOIN element_type et   ON et.element_type_id = e.element_type_id
JOIN well w            ON w.well_id = e.well_id
WHERE t.result = 'FAIL'
  AND NOT EXISTS (SELECT 1 FROM integrity_issue i
                  WHERE i.element_id = t.element_id
                    AND i.detected_date >= t.test_date)

UNION ALL

SELECT 'Annulus reading missing', w.well_name,
       'Annulus ' || a.annulus_name, r.reading_date
FROM annulus_reading r
JOIN annulus a ON a.annulus_id = r.annulus_id
JOIN well w    ON w.well_id = a.well_id
WHERE r.pressure_bar IS NULL

UNION ALL

SELECT 'Closed issue with no intervention', w.well_name, i.category, i.closed_date
FROM integrity_issue i
JOIN well w ON w.well_id = i.well_id
WHERE i.issue_status = 'Closed'
  AND NOT EXISTS (SELECT 1 FROM intervention v WHERE v.issue_id = i.issue_id)

ORDER BY record_date;
