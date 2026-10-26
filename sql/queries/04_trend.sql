-- Rising annulus pressure
-- Annuli where pressure rose at each of the last two readings. A steady rise after bleed-down is the typical sign of sustained casing pressure, often before MAASP is reached.

-- Annuli with pressure rising at each of the last two readings
WITH r AS (
  SELECT annulus_id, reading_date, pressure_bar,
         LAG(pressure_bar, 1) OVER (PARTITION BY annulus_id ORDER BY reading_date) AS prev1,
         LAG(pressure_bar, 2) OVER (PARTITION BY annulus_id ORDER BY reading_date) AS prev2,
         ROW_NUMBER()         OVER (PARTITION BY annulus_id ORDER BY reading_date DESC) AS rn
  FROM annulus_reading
)
SELECT w.well_name,
       a.annulus_name AS annulus,
       r.prev2, r.prev1, r.pressure_bar AS latest,
       r.pressure_bar - r.prev2 AS rise_bar,
       a.maasp_bar,
       ROUND(100.0 * r.pressure_bar / a.maasp_bar, 0) AS pct_of_maasp
FROM r
JOIN annulus a ON a.annulus_id = r.annulus_id
JOIN well w    ON w.well_id = a.well_id
WHERE r.rn = 1
  AND r.pressure_bar > r.prev1
  AND r.prev1 > r.prev2
  AND r.pressure_bar - r.prev2 >= 5
ORDER BY rise_bar DESC;
