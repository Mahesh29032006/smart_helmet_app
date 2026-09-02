# SMART HELMET EMERGENCY RESPONSE PLATFORM
## Project Constitution

**Project:** SIH PS-06 — Low-Cost IoT Smart Helmet for Accident Detection & Rider Safety
**Status:** Active Development (Hackathon Phase)
**Hardware Status:** 🔴 NOT AVAILABLE (Sensors arriving later)

---

## ⚠️ CRITICAL ASSUMPTIONS (DO NOT CHANGE)
1. **No Physical Sensors Yet:** We DO NOT have MPU6050, GPS, or GSM modules right now.
2. **Simulation is Mandatory:** We will build a `SensorSimulator` that produces the exact same data format as the real hardware.
3. **Hardware Abstraction:** The **Crash Detection Engine** must NEVER know whether data comes from a real IMU or the simulator. It only consumes a `SensorData` interface.
4. **Replaceability:** When sensors arrive, we simply switch the Provider from `SimulatorProvider` to `RealHardwareProvider`. No other code changes.

---

## 🧠 CORE ENGINEERING RULES
- **Modularity:** Every feature must belong to a specific layer (Input / Detection / Decision / Backend / UI).
- **No Hardcoding:** GPS coordinates, crash thresholds, and sensor values must be configurable.
- **No Fake AI:** We will not claim "97% accuracy" without a real dataset.
- **Explainability:** The crash detector must output *why* it triggered (Impact Score + Orientation Change + Inactivity).

---

## 🚀 CORE FLOW (THE GOLDEN PATH)
Sensor Input (Simulator/Real) 
    → `SensorData` Model 
    → Crash Detection Engine (Impact + Orientation + Inactivity) 
    → State Machine (SUSPECTED → COUNTDOWN → CONFIRMED/CANCELLED) 
    → Location Provider (Simulated/Real GPS) 
    → Incident Creation (Backend API) 
    → Responder Assignment (Mock/Dummy) 
    → Dashboard UI

---

## ❌ OUT OF SCOPE (DO NOT BUILD UNLESS ASKED)
- Blockchain
- Facial Recognition
- Voice Commands
- Generative AI models
- Complex mobile app features (we use Flutter for dashboards if needed, but focus on core loop first).

# Smart Helmet Emergency Response Platform

## Project Identity

Project: Low-Cost IoT Smart Helmet for Accident Detection & Rider Safety

Hackathon: Smart India Hackathon / internal hackathon prototype

Problem Statement: PS-06

Category: Hardware

Theme: Smart Vehicles

---

# 1. Project Goal

The system is intended to reduce the delay between a probable two-wheeler crash and emergency notification/response.

The official core problem is:

Crash Detection
→ GPS Location
→ Emergency Alert
→ False-Alarm Cancellation

Our proposed extension adds:

Crash Detection
→ Sensor Evidence
→ Crash Verification
→ Incident Creation
→ Responder Selection
→ Ambulance/ Hospital Notification
→ Live Status Tracking
→ Incident Closure

For the hackathon, hospitals and ambulances are simulated/mock entities unless real institutional integration is explicitly available.

Never claim real hospital/ambulance integration when it is not real.

---

# 2. Current Hardware Constraint

Physical sensors/modules are NOT available yet.

Therefore the software must initially operate using simulated sensor data.

This is NOT a separate fake system.

The simulator must implement the same SensorData interface that future physical hardware will implement.

Current:

Sensor Simulator
→ SensorData
→ Crash Detection Engine

Future:

MPU6050 / IMU
→ ESP32 / MCU
→ SensorData
→ Crash Detection Engine

The downstream system must not care whether SensorData originated from real hardware or simulation.

---

# 3. Core Engineering Principle

Use abstraction boundaries.

Sensor input must be replaceable.

Location input must be replaceable.

Notification transport must be replaceable.

Responder integrations must be replaceable.

The system should therefore use:

SensorProvider
LocationProvider
NotificationProvider
ResponderProvider

or equivalent interfaces appropriate to the chosen technology.

---

# 4. Core Crash Detection Philosophy

Do NOT treat one acceleration spike as proof of a crash.

The prototype should consider multiple signals where available:

- acceleration / impact magnitude
- orientation change
- angular velocity
- post-impact inactivity
- temporal relationship between signals
- cancellation window

The prototype must be explainable.

The system should expose evidence such as:

Impact:
Orientation change:
Angular velocity:
Post-impact movement:
Confidence:
Decision:

No unsupported accuracy percentage should be claimed.

No medical or safety certification should be claimed.

---

# 5. Core State Machine

The exact final state names may be refined during architecture design, but the intended lifecycle is:

NORMAL
↓
IMPACT_SUSPECTED
↓
AWAITING_CONFIRMATION
↓
CRASH_CONFIRMED
↓
INCIDENT_CREATED
↓
DISPATCHED
↓
ACKNOWLEDGED
↓
EN_ROUTE
↓
ARRIVED
↓
PATIENT_PICKED_UP
↓
HOSPITAL_RECEIVED
↓
CLOSED

Cancellation path:

IMPACT_SUSPECTED / AWAITING_CONFIRMATION
↓
CANCELLED
↓
NORMAL

Failure paths must be explicitly represented.

---

# 6. Sensor Simulation

The simulator must generate realistic time-series data, not merely:

crash = true

Required scenarios:

1. Normal riding
2. Normal movement
3. Sudden braking
4. Pothole/bump
5. Helmet drop
6. Minor impact
7. Major impact
8. Major impact + orientation change + inactivity
9. Impact followed by cancellation
10. Impact followed by continued movement
11. Sensor noise
12. Missing/invalid sensor data

The simulator should expose raw sensor values.

---

# 7. Location Architecture

Location must support:

1. Simulated GPS
2. Future real GPS
3. Cached location
4. Stale location
5. No GPS fix

The incident system must not directly depend on one GPS module.

---

# 8. Notification Architecture

Notification must be abstracted.

Possible implementations:

1. Simulation/logging
2. GSM/SMS
3. Backend notification
4. Future external provider

The hackathon must clearly distinguish simulated notifications from real SMS.

---

# 9. Emergency Response

After a confirmed crash:

1. Create incident
2. Validate event
3. Determine severity/priority
4. Identify appropriate available responder
5. Assign ambulance
6. Notify responder
7. Responder accepts/rejects
8. Track response
9. Notify hospital
10. Close incident
11. Preserve event history

Responders are mock entities for the hackathon unless officially integrated.

---

# 10. Important Entities

Likely entities include:

- Rider
- Device
- SensorEvent
- Incident
- IncidentStatusHistory
- Hospital
- Ambulance
- Responder
- Dispatch
- Notification
- AuditLog

Exact schema will be finalized in docs/04_DATABASE.md.

---

# 11. Technology Direction

Technology must be selected based on:

- implementation speed
- reliability
- debugging ability
- team familiarity
- free/low-cost availability
- hackathon suitability
- ability to integrate with future hardware

Initial direction:

Frontend:
React + Vite + TypeScript

Backend:
Node.js + Express + TypeScript

Database:
PostgreSQL

Realtime:
Socket.IO

Maps:
Leaflet + OpenStreetMap unless another choice is justified

Hardware:
ESP32/compatible MCU + IMU + GPS + cellular module when available

Sensor simulator:
Same SensorData contract as real hardware

Final technology decisions must be documented in docs/03_ARCHITECTURE.md and docs/08_DECISIONS.md.

---

# 12. What Is NOT Currently a Priority

Do not add these merely to make the project look advanced:

- Blockchain
- Facial recognition
- Voice assistant
- Camera streaming
- unnecessary AI/ML
- alcohol detection unless requirements explicitly change
- complex mobile application
- real hospital integration without authorization
- real ambulance integration without authorization
- excessive UI animations
- unnecessary microservices

---

# 13. Real vs Simulated Components

Current:

Sensor input:
SIMULATED

GPS:
SIMULATED

Responder:
MOCK

Hospital:
MOCK

Ambulance:
MOCK

Backend:
REAL APPLICATION

Database:
REAL DATABASE

Crash detection:
REAL APPLICATION LOGIC

Incident workflow:
REAL APPLICATION LOGIC

Frontend:
REAL APPLICATION

When hardware arrives, the physical sensor layer will replace only the simulated input layer.

---

# 14. Development Order

1. Requirements
2. Research
3. Architecture
4. SensorData interface
5. Sensor simulator
6. Crash detection
7. State machine
8. Location abstraction
9. Incident model
10. Backend/API
11. Database
12. Responder workflow
13. Frontend
14. Integration
15. Testing
16. Hardware integration
17. Demo
18. Judge stress-test

---

# 15. Change Management Rule

Whenever a new requirement is introduced:

DO NOT immediately code.

Perform:

Requirement
→ Classify
→ Impact analysis
→ Identify owning module
→ Update architecture/contracts
→ Implement
→ Regression test

Whenever a feature is removed:

Dependency analysis
→ Decouple
→ Remove
→ Regression test

Whenever a technology/component changes:

Compare interfaces
→ Determine compatibility
→ Adapt provider
→ Retest

---

# 16. AI Rules

AI tools are implementation assistants, not project owners.

Every AI agent must:

1. Read this document.
2. Read relevant project documentation.
3. Inspect the existing repository.
4. Preserve existing interfaces.
5. Avoid unrelated changes.
6. Run tests.
7. Report changes.
8. Report incomplete work.
9. Never fabricate test results.
10. Never fabricate real-world integrations.
11. Never silently redesign architecture.

---

# 17. Source of Truth

Authoritative documents:

docs/00_MASTER_CONTEXT.md
docs/01_REQUIREMENTS.md
docs/02_RESEARCH.md
docs/03_ARCHITECTURE.md
docs/04_DATABASE.md
docs/05_API_CONTRACT.md
docs/06_SENSOR_SIMULATION.md
docs/07_TEST_PLAN.md
docs/08_DECISIONS.md
docs/09_CHANGELOG.md
docs/10_AI_HANDOFF.md

Git repository is the persistent project memory.

AI conversations are NOT the source of truth.

---



# 19. Current Next Action

Complete the requirements document.

Do not start implementation until the requirements and architecture
have been reviewed.
