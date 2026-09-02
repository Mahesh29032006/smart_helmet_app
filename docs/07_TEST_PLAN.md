# Test Plan

Status: DRAFT

Test categories:

## Sensor
- normal riding
- pothole
- braking
- helmet drop
- impact
- noise
- invalid data

## Detection
- false positives
- false negatives
- impact detection
- orientation
- inactivity
- confidence/explanation

## State Machine
- cancellation
- confirmation
- duplicate events
- failure states
- recovery

## GPS
- fresh
- stale
- unavailable
- cached

## Backend
- valid event
- invalid event
- duplicate event
- missing device
- database failure

## Responder
- assignment
- acceptance
- rejection
- no available responder
- timeout

## Frontend
- loading
- success
- error
- realtime update
- empty state

## End-to-End
Sensor
→ Detection
→ Confirmation
→ Incident
→ Dispatch
→ Response
→ Closure

Actual test results must be recorded after implementation.
