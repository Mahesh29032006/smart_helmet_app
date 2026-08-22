# RescueLink API & WebSocket Contract

## 1. REST Endpoints

### `POST /api/v1/incidents`
Creates a new emergency incident.
- **Request Body**:
```json
{
  "id": "inc-1700000000",
  "timestamp": "2026-08-23T02:45:00.000Z",
  "location": {
    "latitude": 20.2961,
    "longitude": 85.8245,
    "accuracy": 5.0,
    "speed": 0.0,
    "heading": 0.0,
    "timestamp": "2026-08-23T02:45:00.000Z"
  },
  "severity": "critical",
  "status": "open",
  "crashConfidence": 0.98
}
```
- **Response**: `201 Created` with incident object.

### `GET /api/v1/responders/nearest`
Queries nearest candidate emergency units.
- **Query Parameters**:
  - `latitude`: `double`
  - `longitude`: `double`
  - `radiusKm`: `double` (default: 10.0)
  - `type`: `ambulance` | `hospital` | `police` | `fire`

## 2. WebSocket / Socket.IO Events

### Incoming Events (Server -> Client)
- `incident.dispatched`: Sent when responder is assigned.
- `responder.accepted`: Sent when responder acknowledges.
- `responder.location_updated`: Sent when responder moves.
- `responder.arrived`: Sent when responder reaches scene.
- `incident.closed`: Sent when incident is completed.
- `incident.cancelled`: Sent when incident is cancelled.

### Outgoing Events (Client -> Server)
- `incident.subscribe`: `{ "incidentId": "inc-123" }`
- `incident.unsubscribe`: `{ "incidentId": "inc-123" }`
- `responder.accept`: `{ "incidentId": "inc-123", "responderId": "amb-01" }`
- `responder.reject`: `{ "incidentId": "inc-123", "responderId": "amb-01" }`
- `responder.update_location`: `{ "responderId": "amb-01", "location": { ... } }`
