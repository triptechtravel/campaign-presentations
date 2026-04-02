-- Tourism regions visited per user per month, with domestic/international split
-- Same event filter and home country logic as travel spread query

WITH events_filtered AS (
  SELECT
    e.user_id,
    FORMAT_TIMESTAMP("%Y-%m", e.utc_created_timestamp) AS month,
    EXTRACT(YEAR FROM e.utc_created_timestamp) AS yr,
    e.tourism_region,
    COALESCE(u.home_country, ulc.country) AS home_country
  FROM `triptech.analytics_prod.stg_geozone_user_event` e
  LEFT JOIN `triptech.analytics_prod.stg_geozone_user` u ON e.user_id = u.user_id
  LEFT JOIN `triptech.dbt_hg.tmp_user_locale` ll ON e.user_id = ll.user_id AND u.user_id IS NULL
  LEFT JOIN `triptech.nzau_analytics.user_locale_to_country_continent_mapping` ulc ON ll.locale = ulc.home_user
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
    CASE
      WHEN home_country = "Australia" THEN "Domestic"
      WHEN home_country IS NULL OR home_country = "Unknown" THEN "Unclassified"
      ELSE "International"
    END AS origin,
    COUNT(DISTINCT tourism_region) AS region_count,
    COUNT(*) AS ping_count
  FROM events_filtered
  GROUP BY user_id, month, yr, origin
  HAVING ping_count >= 3
)
SELECT month, yr, origin,
  COUNT(*) AS users,
  ROUND(AVG(region_count), 2) AS avg_regions,
  ROUND(COUNTIF(region_count = 1) / COUNT(*) * 100, 1) AS pct_single_region
FROM user_regions
WHERE month IN ("2025-01","2025-02","2025-03","2026-01","2026-02","2026-03")
GROUP BY month, yr, origin
ORDER BY month, yr, origin;
