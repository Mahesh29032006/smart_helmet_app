# Requirements Baseline (Extracted from PS-06)

## A. MANDATORY REQUIREMENTS (MUST HAVE)
| # | Requirement | Source |
|---|-------------|--------|
| 1 | Detect crash using accelerometer/gyroscope (Impact detection) | PS Line 1 |
| 2 | Obtain GPS coordinates upon detection | PS Line 1 |
| 3 | Send SMS with live location to a preset emergency contact | PS Line 1 |
| 4 | Manual "false-alarm cancel" button (cancellation window) | PS Line 2 |

## B. STRONGLY IMPLIED (SHOULD HAVE)
- Distinguish genuine crash from potholes, drops, or sudden braking.
- Provide a countdown (e.g., 10 seconds) before sending the SMS.
- Handle GPS/Network failures gracefully.

## C. OPTIONAL / STRETCH (MAY HAVE)
- Alcohol sensing (explicitly listed as Stretch Goal).
- Companion app for contact management (Stretch Goal).
- Hospital/Ambulance integration (Stretch Goal, we will use Mock data).

## D. EXCLUDED (DO NOT BUILD)
- Blockchain.
- Complex cloud infrastructure for MVP.
- Production-ready helmet shell (breadboard is fine).
- Certified medical accuracy.

## E. CONSTRAINTS
- Breadboard/Simulated sensor feed is acceptable (given in Implementation Notes).
- Must be a working core loop over feature bloat.
