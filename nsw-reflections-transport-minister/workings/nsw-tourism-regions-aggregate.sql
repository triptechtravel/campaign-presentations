-- Aggregate tourism regions per user (no domestic/international split)
-- Based on campaign-presentations workings/03-tourism-regions.sql
-- Same event filter, drops origin classification

WITH events_filtered AS (
  SELECT
    e.user_id,
    FORMAT_TIMESTAMP("%Y-%m", e.utc_created_timestamp) AS month,
    EXTRACT(YEAR FROM e.utc_created_timestamp) AS yr,
    e.tourism_region
  FROM `triptech.analytics_prod.stg_geozone_user_event` e
  WHERE e.utc_created_timestamp >= "2025-01-01"
    AND e.utc_created_timestamp < "2026-04-01"
    AND e.state = "New South Wales"
    AND e.tourism_region IS NOT NULL
    AND (
      (e.app_name = "CamperMate" AND e.app_version LIKE "5.%" AND e.app_platform = "iOS")
      OR e.event_name IN ("location_change", "location_ping")
    )
),
user_regions AS (
  SELECT
    user_id, month, yr,
    COUNT(DISTINCT tourism_region) AS region_count,
    COUNT(*) AS ping_count
  FROM events_filtered
  GROUP BY user_id, month, yr
  HAVING ping_count >= 3
)
SELECT month, yr,
  COUNT(*) AS users,
  ROUND(AVG(region_count), 2) AS avg_regions,
  ROUND(COUNTIF(region_count = 1) / COUNT(*) * 100, 1) AS pct_single_region
FROM user_regions
WHERE month IN ("2025-01","2025-02","2025-03","2026-01","2026-02","2026-03")
GROUP BY month, yr
ORDER BY month, yr;
