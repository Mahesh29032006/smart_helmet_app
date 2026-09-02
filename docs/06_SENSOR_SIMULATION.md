# Sensor Simulation Scenarios

We will generate time-series data to test the system.

## Scenario 1: Normal Riding
- Small vibrations (ax: 0.5–1.5, ay: 0.5–1.5, az: 0.8–1.2).
- Movement: true.
- **Expected:** System stays in `NORMAL`.

## Scenario 2: Pothole / Bump
- Sharp spike in acceleration (e.g., ax: 4.0).
- Orientation change: minimal (< 5°).
- Movement: continues.
- **Expected:** `IMPACT_SUSPECTED` but returns to `NORMAL` (false positive avoided).

## Scenario 3: Genuine Crash
- Massive spike (ax: 8.0, ay: 4.0, az: 12.0).
- Orientation change: sudden > 30°.
- Movement: stops (0 velocity).
- **Expected:** `IMPACT_SUSPECTED` → `AWAITING_CONFIRMATION` → Countdown → `CONFIRMED`.

## Scenario 4: Helmet Drop
- Spike (ax: 6.0).
- Orientation change: minimal.
- Movement: stops.
- **Expected:** `CANDIDATE` but likely cancelled or returned based on orientation logic.


# Sensor Simulation Specification

Status: DRAFT

Purpose:

Allow the complete application to be developed and tested before the
physical sensors arrive.

The simulator must behave like a sensor source, not like a shortcut
that directly says "crash".

Required scenarios:

- normal riding
- braking
- pothole
- helmet drop
- minor impact
- major impact
- orientation change
- inactivity after impact
- cancellation
- continued movement after impact
- noise
- invalid sensor values

The simulator must produce SensorData using the same interface that
future physical hardware will use.

The crash engine must not know whether the source is real or simulated.
