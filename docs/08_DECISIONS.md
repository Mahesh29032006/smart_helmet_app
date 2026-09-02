
---

#### 📄 File: `docs/08_DECISIONS.md` (The Logbook)
```markdown
# Architecture Decision Log (ADL)

## Decision 1: Simulate Sensors First
**Date:** 2025-03-XX
**Context:** No physical IMU/GPS/GSM modules available.
**Decision:** Build a `SensorSimulator` that produces the exact same `SensorData` structure as the real hardware.
**Alternatives considered:** Building a dummy UI that just sends hardcoded alerts.
**Consequence:** The detection engine is decoupled from hardware. We can build 90% of the logic today. Later, we just swap the provider.
**Status:** Accepted.

## Decision 2: Multi-Signal Crash Detection
**Date:** 2025-03-XX
**Context:** Single threshold (e.g., >5g) causes false positives on potholes/drops.
**Decision:** Combine 3 signals: (1) Impact Magnitude, (2) Orientation Change, (3) Post-Impact Inactivity.
**Alternatives considered:** Using a simple accelerometer threshold.
**Consequence:** Slightly more complex code, but drastically reduces false alarms.
**Status:** Accepted.

## Decision 3: No AI/ML in MVP
**Date:** 2025-03-XX
**Context:** Lack of labelled crash dataset.
**Decision:** Use deterministic, explainable thresholds.
**Alternatives considered:** Claiming "AI-driven detection".
**Consequence:** Honest and defensible. Can add ML later when data exists.
**Status:** Accepted.


# Architecture Decision Log

| ID | Date | Decision | Reason | Consequence | Status |
|---|---|---|---|---|---|
| ADR-001 | 2026-08-23 | Use sensor abstraction | Physical hardware unavailable initially | Simulator and real hardware can share interface | ACCEPTED |
| ADR-002 | 2026-08-23 | Build simulator before hardware | Hardware unavailable | Software can proceed immediately | ACCEPTED |
| ADR-003 | 2026-08-23 | Use deterministic crash scenarios | Need reproducible testing | Repeatable demonstrations and tests | ACCEPTED |

## Rules

Never silently reverse an existing architectural decision.

If a decision must change:

1. Explain why.
2. Identify affected modules.
3. Identify migration work.
4. Record the new decision here.
5. Run regression tests.
