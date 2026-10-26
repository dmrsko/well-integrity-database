-- Annulus pressure against MAASP
-- Latest reading for every annulus as a percentage of its MAASP (maximum allowable annulus surface pressure), highest first.

-- Latest annulus pressure as % of MAASP
WITH latest AS (
  SELECT r.annulus_id, r.reading_date, r.pressure_bar,
         ROW_NUMBER() OVER (PARTITION BY r.annulus_id ORDER BY r.reading_date DESC) AS rn
  FROM annulus_reading r
  WHERE r.pressure_bar IS NOT NULL
)
SELECT w.well_name,
       a.annulus_name AS annulus,
       l.reading_date,
       l.pressure_bar,
       a.maasp_bar,
       ROUND(100.0 * l.pressure_bar / a.maasp_bar, 1) AS pct_of_maasp,
       CASE WHEN l.pressure_bar > a.maasp_bar        THEN 'Above MAASP'
            WHEN l.pressure_bar >= 0.8 * a.maasp_bar THEN 'Warning (80%+)'
            ELSE 'Normal' END AS flag
FROM latest l
JOIN annulus a ON a.annulus_id = l.annulus_id
JOIN well w    ON w.well_id = a.well_id
WHERE l.rn = 1
ORDER BY pct_of_maasp DESC;
