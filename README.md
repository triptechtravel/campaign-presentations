# TripTech Campaign Presentations

Interactive HTML presentations for TripTech campaign performance reporting. Each campaign lives in its own folder under `campaigns/`.

## Campaigns

| Campaign | Folder | Live Preview |
|----------|--------|-------------|
| KiwiNorth 2026 | [campaigns/kiwi-north-2026/](campaigns/kiwi-north-2026/) | [View →](https://htmlpreview.github.io/?https://raw.githubusercontent.com/triptechtravel/campaign-presentations/main/campaigns/kiwi-north-2026/presentation.html) |

## Structure

```
campaigns/
  <campaign-slug>/
    presentation.html   # Self-contained interactive HTML presentation
```

## Adding a New Campaign

1. Create a folder under `campaigns/` using a kebab-case slug (e.g. `campaigns/summer-au-2026/`)
2. Add `presentation.html` — a self-contained HTML file with all CSS and JS inline
3. Update the table in this README with the campaign name and preview link
