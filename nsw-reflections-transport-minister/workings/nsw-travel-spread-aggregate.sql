-- Aggregate travel spread (no domestic/international split)
-- Based on campaign-presentations workings/02-travel-spread.sql
-- Drops the origin classification entirely — gives true aggregate percentiles
--
-- Event filter logic:
--   - CamperMate 5.x iOS (React Native): all events (user GPS in $.userAgent meta on every event)
--   - Everything else (old CamperMate Android, thl Roadtrip all versions, old CamperMate iOS): location_change + location_ping only

WITH events_filtered AS (
  SELECT
    e.user_id,
    FORMAT_TIMESTAMP("%Y-%m", e.utc_created_timestamp) AS month,
    EXTRACT(YEAR FROM e.utc_created_timestamp) AS yr,
    e.latitude, e.longitude
  FROM `triptech.analytics_prod.stg_geozone_user_event` e
  WHERE e.utc_created_timestamp >= "2025-01-01"
    AND e.utc_created_timestamp < "2026-04-01"
    AND e.state = "New South Wales"
    AND e.latitude IS NOT NULL AND e.longitude IS NOT NULL
    AND (
      (e.app_name = "CamperMate" AND e.app_version LIKE "5.%" AND e.app_platform = "iOS")
      OR e.event_name IN ("location_change", "location_ping")
    )
),
user_monthly AS (
  SELECT
    user_id, month, yr,
    MIN(latitude) AS min_lat, MAX(latitude) AS max_lat,
    MIN(longitude) AS min_lng, MAX(longitude) AS max_lng,
    COUNT(*) AS ping_count
  FROM events_filtered
  GROUP BY user_id, month, yr
  HAVING ping_count >= 3
),
with_spread AS (
  SELECT *, ST_DISTANCE(ST_GEOGPOINT(min_lng, min_lat), ST_GEOGPOINT(max_lng, max_lat)) / 1000.0 AS spread_km
  FROM user_monthly
)
SELECT month, yr,
  COUNT(*) AS users,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(10)], 1) AS p10,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(25)], 1) AS p25,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(50)], 1) AS p50_median,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(75)], 1) AS p75,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(90)], 1) AS p90,
  ROUND(AVG(spread_km), 1) AS avg_spread
FROM with_spread
WHERE month IN ("2025-01","2025-02","2025-03","2026-01","2026-02","2026-03")
GROUP BY month, yr
ORDER BY month, yr;
