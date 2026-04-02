-- Travel spread by domestic/international origin
-- Uses partition filter on utc_created_timestamp, cluster on state + event_name
--
-- Event filter logic:
--   - CamperMate 5.x iOS (React Native): all events (user GPS in $.userAgent meta on every event)
--   - Everything else (old CamperMate Android, thl Roadtrip all versions, old CamperMate iOS): location_change + location_ping only
--
-- Home country resolution:
--   1. stg_geozone_user.home_country (for users matched in user table)
--   2. locale from $.userAgent → user_locale_to_country_continent_mapping (for unmatched 5.x users)
--   3. NULL → "Unclassified" (likely domestic, near-zero travel)

WITH events_filtered AS (
  SELECT
    e.user_id,
    FORMAT_TIMESTAMP("%Y-%m", e.utc_created_timestamp) AS month,
    EXTRACT(YEAR FROM e.utc_created_timestamp) AS yr,
    e.latitude, e.longitude, e.tourism_region,
    COALESCE(u.home_country, ulc.country) AS home_country
  FROM `triptech.analytics_prod.stg_geozone_user_event` e
  LEFT JOIN `triptech.analytics_prod.stg_geozone_user` u ON e.user_id = u.user_id
  LEFT JOIN `triptech.dbt_hg.tmp_user_locale` ll ON e.user_id = ll.user_id AND u.user_id IS NULL
  LEFT JOIN `triptech.nzau_analytics.user_locale_to_country_continent_mapping` ulc ON ll.locale = ulc.home_user
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
    CASE
      WHEN home_country = "Australia" THEN "Domestic"
      WHEN home_country IS NULL OR home_country = "Unknown" THEN "Unclassified"
      ELSE "International"
    END AS origin,
    MIN(latitude) AS min_lat, MAX(latitude) AS max_lat,
    MIN(longitude) AS min_lng, MAX(longitude) AS max_lng,
    COUNT(*) AS ping_count
  FROM events_filtered
  GROUP BY user_id, month, yr, origin
  HAVING ping_count >= 3
),
with_spread AS (
  SELECT *, ST_DISTANCE(ST_GEOGPOINT(min_lng, min_lat), ST_GEOGPOINT(max_lng, max_lat)) / 1000.0 AS spread_km
  FROM user_monthly
)
SELECT month, yr, origin,
  COUNT(*) AS users,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(10)], 1) AS p10,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(25)], 1) AS p25,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(50)], 1) AS p50_median,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(75)], 1) AS p75,
  ROUND(APPROX_QUANTILES(spread_km, 100)[OFFSET(90)], 1) AS p90,
  ROUND(AVG(spread_km), 1) AS avg_spread
FROM with_spread
WHERE month IN ("2025-01","2025-02","2025-03","2026-01","2026-02","2026-03")
GROUP BY month, yr, origin
ORDER BY month, yr, origin;
