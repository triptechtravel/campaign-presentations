-- Step 1: Build user locale lookup for CamperMate 5.x users
-- These users use Firebase UIDs and aren't in stg_geozone_user (which only handles 5.0-5.2)
-- The 5.x app sends userAgent in $.userAgent (not $.meta.userAgent) with format:
--   CamperMate/5.5.0 (iPhone; iOS 18.4.1; iPhone 16 Plus; Build/177) en-AU
-- Locale is the last token.
--
-- Materialized to: triptech.dbt_hg.tmp_user_locale
-- Cost: ~1.7 GB (58 partition days from raw source)

SELECT
  ue.user_uid AS user_id,
  ANY_VALUE(
    REGEXP_EXTRACT(
      JSON_EXTRACT_SCALAR(ue.parameters, "$.userAgent"),
      r"(\S+)$"
    )
  ) AS locale
FROM `triptech.geozone_business.user_event_app` ue
WHERE date(ue.created_at) IN (
  -- Jan 2025
  "2025-01-03","2025-01-06","2025-01-09","2025-01-12","2025-01-15","2025-01-18","2025-01-21","2025-01-24","2025-01-27","2025-01-30",
  -- Feb 2025
  "2025-02-03","2025-02-06","2025-02-09","2025-02-12","2025-02-15","2025-02-18","2025-02-21","2025-02-24","2025-02-27",
  -- Mar 2025
  "2025-03-03","2025-03-06","2025-03-09","2025-03-12","2025-03-15","2025-03-18","2025-03-21","2025-03-24","2025-03-27","2025-03-30",
  -- Jan 2026
  "2026-01-03","2026-01-06","2026-01-09","2026-01-12","2026-01-15","2026-01-18","2026-01-21","2026-01-24","2026-01-27","2026-01-30",
  -- Feb 2026
  "2026-02-03","2026-02-06","2026-02-09","2026-02-12","2026-02-15","2026-02-18","2026-02-21","2026-02-24","2026-02-27",
  -- Mar 2026
  "2026-03-03","2026-03-06","2026-03-09","2026-03-12","2026-03-15","2026-03-18","2026-03-21","2026-03-24","2026-03-27","2026-03-30"
)
AND ue.user_uid IS NOT NULL
AND JSON_EXTRACT_SCALAR(ue.parameters, "$.userAgent") LIKE "CamperMate/5.%"
GROUP BY 1;

-- Result: 45,306 users with locale
