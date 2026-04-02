# Ping Threshold Sensitivity Analysis

## Context

The CamperMate 5.x iOS app (React Native) attaches GPS to every user interaction event, generating significantly more location readings per user than the old native app (which only fires `location_change`). This raises the question: does the 3-ping minimum threshold pull in more casual/stationary users in 2026, inflating the apparent decline?

## Results — March YoY

### Domestic

| Min pings | Mar 2025 P50 | Mar 2026 P50 | YoY decline | 2025 users | 2026 users |
|-----------|-------------|-------------|-------------|------------|------------|
| 3+ | 46.6 km | 8.5 km | -82% | 4,412 | 4,927 |
| 10+ | 158.5 km | 25.5 km | -84% | 2,060 | 3,288 |
| 20+ | 158.5 km | 34.0 km | -79% | 1,511 | 2,644 |
| 50+ | 150.6 km | 52.1 km | -65% | 1,080 | 1,862 |

### International

| Min pings | Mar 2025 P50 | Mar 2026 P50 | YoY decline | 2025 users | 2026 users |
|-----------|-------------|-------------|-------------|------------|------------|
| 3+ | 255.5 km | 143.5 km | -44% | 6,578 | 7,015 |
| 10+ | 432.7 km | 235.5 km | -46% | 3,898 | 5,280 |
| 20+ | 474.4 km | 269.8 km | -43% | 2,678 | 4,388 |
| 50+ | 458.5 km | 338.7 km | -26% | 1,471 | 3,188 |

### Overall (all origins combined)

| Min pings | Mar 2025 P50 | Mar 2026 P50 | YoY decline | 2025 users | 2026 users |
|-----------|-------------|-------------|-------------|------------|------------|
| 3+ | 140.8 km | 15.0 km | -89% | 11,182 | 14,277 |
| 10+ | 354.3 km | 53.3 km | -85% | 6,057 | 10,080 |
| 20+ | 376.8 km | 73.6 km | -80% | 4,254 | 8,202 |
| 50+ | 313.0 km | 128.1 km | -59% | 2,590 | 5,738 |

## Conclusion

The 5.x ping effect inflates the headline decline by ~15–20 percentage points for domestic users and ~18pp for international. But the underlying decline is real at every threshold:

- **Domestic**: -65% to -84% depending on threshold
- **International**: -26% to -46% depending on threshold

The 3-ping threshold is consistent with the original methodology and the dashboard uses qualitative language in the key findings rather than quoting exact percentages. No change to the dashboard output recommended.
