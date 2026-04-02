# Validation Notes

## Investigation Summary

The original dashboard used `location_change` events only, which missed:
1. `location_ping` — a new 5.x foreground GPS event with no old-app equivalent
2. All CamperMate 5.x iOS events — which embed user GPS in every event via `$.userAgent` meta

Including these additional events brings ~3,000 more users into March 2026 and significantly changes the story when split by origin.

## Event Filter Discovery

### Old native apps (CamperMate Android, thl Roadtrip all versions, CamperMate iOS < 5.x)
- Only `location_change` carries reliable user GPS
- thl Roadtrip uses independent versioning — 5.x on thl ≠ new React Native app

### CamperMate 5.x iOS (React Native)
- ALL events embed user GPS in `$.userAgent` meta
- 100% of 5.x events have location data
- New event names: `location_ping`, `map_marker_clicked`, `poi_peek_viewed`, `poi_card_clicked`, etc.
- Event names are UPPERCASED in raw source (e.g., `BANNER_AD_IMPRESSION`)
- `user_id` is NULL; uses `user_uid` (Firebase UID) as identifier

### 5.x User Identification Gap
- `stg_geozone_user` dbt model only handles app versions 5.0.0, 5.1.0, 5.2.0
- Users on 5.3+ (including 5.4.1, 5.5.0) are not created in the user table
- Workaround: extract locale from `$.userAgent` in raw events → map via `user_locale_to_country_continent_mapping`
- 58-day sample across 6 months captured 45,306 users; ~2,335 remain unclassified in March 2026

## Data Source Verification

- Confirmed `analytics_prod.stg_geozone_user_event` has full date range (Jan 2025 – Apr 2026)
- `dbt_hg.stg_geozone_user_event` is stale (only Nov 2025 data) — do not use
- `analytics_prod.stg_ga_user_event` only starts Nov 2025 — cannot cover 2025 comparison period
- Raw source `geozone_business.user_event_app` is partitioned by `created_at` (DAY)

## Lat/Lng Verification

Confirmed that even for old native events, the staging table lat/lng is the USER's location, not the POI's:
- Tested `poi_marker_tapped` events: event lat/lng was Newcastle (-32.94, 151.72) while POI was in WA (-34.08, 115.02)
- The `ifnull(ue.longitude, parameters.$.user_location)` extraction in the staging model correctly uses user location

## App Version Distribution (March 2026, NSW)

| App | Platform | Version | Users/day |
|-----|----------|---------|-----------|
| CamperMate | iOS | 5.x | ~1,040 |
| CamperMate | Android | old | ~416 |
| thl Roadtrip | iOS | 5.x* | ~455 |
| thl Roadtrip | Android | 5.x* | ~93 |
| CamperMate | iOS | old | ~41 |

*thl 5.x = old native codebase with different versioning

## v5 Event Adoption Over Time

| Month | v5 % | Old % |
|-------|------|-------|
| Jan 2025 | 19.2% | 80.8% |
| Mar 2025 | 19.7% | 80.3% |
| Jan 2026 | 51.2% | 48.8% |
| Mar 2026 | 80.5% | 19.5% |

## Final Results

### Travel Spread — Median P50 (km)

| Month | Domestic | International | Unclassified |
|-------|----------|---------------|--------------|
| Jan 25 | 59.5 (5,744) | 243.5 (7,436) | 118.0 (361) |
| Feb 25 | 43.8 (3,998) | 253.8 (6,046) | 111.9 (170) |
| Mar 25 | 46.7 (4,412) | 255.5 (6,578) | 67.1 (192) |
| Jan 26 | 43.5 (2,967) | 229.8 (3,987) | 91.9 (173) |
| Feb 26 | 20.9 (2,543) | 177.6 (3,762) | 0.1 (326) |
| Mar 26 | 8.5 (4,929) | 143.5 (7,013) | 0.0 (2,335) |

### Single-Region %

| Month | Domestic | International | Unclassified |
|-------|----------|---------------|--------------|
| Jan 25 | 57.2% | 39.8% | 47.1% |
| Feb 25 | 60.9% | 40.6% | 50.6% |
| Mar 25 | 59.7% | 38.3% | 52.1% |
| Jan 26 | 59.9% | 38.0% | 52.0% |
| Feb 26 | 66.9% | 43.7% | 81.0% |
| Mar 26 | 71.6% | 49.8% | 91.2% |
