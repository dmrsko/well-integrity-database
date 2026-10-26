-- Intervention history
-- Completed and planned interventions, linked to the issue that triggered them, with time from detection to repair.

-- Interventions and time from detection to completed repair
SELECT w.well_name,
       v.intervention_type,
       i.category AS triggered_by,
       i.detected_date,
       v.start_date,
       v.end_date,
       CAST(julianday(v.end_date) - julianday(i.detected_date) AS INTEGER) AS days_detect_to_repair,
       v.rig_days,
       COALESCE(v.outcome, 'Planned') AS outcome
FROM intervention v
JOIN well w ON w.well_id = v.well_id
LEFT JOIN integrity_issue i ON i.issue_id = v.issue_id
ORDER BY v.start_date;
