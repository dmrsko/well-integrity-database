-- Open integrity issues
-- Every open issue with its age in days and whether an intervention is already planned.

-- Open integrity issues, oldest first
WITH s AS (SELECT as_of_date FROM report_settings)
SELECT w.well_name,
       i.category,
       i.severity,
       i.detected_date,
       CAST(julianday(s.as_of_date) - julianday(i.detected_date) AS INTEGER) AS days_open,
       i.description,
       COALESCE(MAX(CASE WHEN v.end_date IS NULL THEN v.intervention_type END), 'None planned') AS planned_intervention
FROM integrity_issue i
JOIN well w ON w.well_id = i.well_id
CROSS JOIN s
LEFT JOIN intervention v ON v.issue_id = i.issue_id
WHERE i.issue_status = 'Open'
GROUP BY i.issue_id, w.well_name, i.category, i.severity, i.detected_date, s.as_of_date, i.description
ORDER BY i.detected_date;
