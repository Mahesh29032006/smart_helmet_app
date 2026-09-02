/**
 * RescueLink Smart Helmet Backend Server
 * Node.js + Express + Socket.IO
 *
 * Extends the existing API contract (docs/05_API_CONTRACT.md).
 * New endpoints for ESP32 telemetry ingestion:
 *   GET  /health
 *   POST /api/v1/telemetry       — helmet telemetry (authenticated)
 *   GET  /api/v1/telemetry/latest
 *   POST /api/v1/events          — helmet emergency events (authenticated)
 *   GET  /api/v1/device/status
 *   POST /api/v1/incidents       — existing contract (now real)
 *   GET  /api/v1/incidents
 *   GET  /api/v1/incidents/:id
 *   PUT  /api/v1/incidents/:id
 *   GET  /api/v1/responders/nearest — existing contract
 *
 * Socket.IO events → Flutter:
 *   sensor.update, location.update, device.update,
 *   emergency.state, incident.created, incident.updated,
 *   incident.dispatched (existing contract)
 */

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

const PORT = parseInt(process.env.PORT || '5001', 10);
const HOST = process.env.HOST || '0.0.0.0';
const DEVICE_TOKEN = process.env.DEVICE_TOKEN || 'change-me';
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

// Thresholds for device online/stale/offline
const STALE_THRESHOLD_MS = 10_000;
const OFFLINE_THRESHOLD_MS = 60_000;

// ─── In-memory store ───────────────────────────────────────────────────────
const latestTelemetry = {};
const latestGps = {};
const deviceLastSeen = {};
const incidents = {};
const hardwareState = {};

// Mock responders (placed near expected helmet test area)
const mockResponders = [
  { id: 'amb-01', name: 'Ambulance A1 (ALS)', type: 'ambulance', status: 'available',
    location: { latitude: 22.259, longitude: 84.920 }, phone: '+91-9876543210',
    vehicleNumber: 'OD-22-EM-1081', traumaCapability: false, rating: 4.9 },
  { id: 'hosp-01', name: 'City Trauma Centre', type: 'hospital', status: 'available',
    location: { latitude: 22.263, longitude: 84.910 }, phone: '+91-674-2500100',
    vehicleNumber: null, traumaCapability: true, rating: 4.95 },
];

// ─── Middleware ────────────────────────────────────────────────────────────
app.use(cors({ origin: CORS_ORIGIN }));
app.use(express.json());

// ─── Socket.IO ─────────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: { origin: CORS_ORIGIN, methods: ['GET', 'POST'] },
});

io.on('connection', (socket) => {
  console.log('[Socket.IO] Client connected:', socket.id);

  // Push latest state immediately on connect
  for (const [did, t] of Object.entries(latestTelemetry)) {
    socket.emit('sensor.update', _sensorPayload(did, t));
  }
  for (const [did, g] of Object.entries(latestGps)) {
    socket.emit('location.update', g);
  }
  for (const [did, s] of Object.entries(hardwareState)) {
    socket.emit('emergency.state', { deviceId: did, state: s });
  }
  for (const inc of Object.values(incidents)) {
    socket.emit('incident.created', inc);
  }

  socket.on('incident.subscribe', (data) => {
    const id = data && data.incidentId;
    if (id) { socket.join('incident:' + id); }
  });
  socket.on('incident.unsubscribe', (data) => {
    const id = data && data.incidentId;
    if (id) { socket.leave('incident:' + id); }
  });
  socket.on('disconnect', () => {
    console.log('[Socket.IO] Client disconnected:', socket.id);
  });
});

// ─── Helpers ───────────────────────────────────────────────────────────────
function deviceAuth(req, res, next) {
  const token = req.headers['x-device-token'];
  if (token !== DEVICE_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized: invalid device token' });
  }
  next();
}

function getDeviceStatus(deviceId) {
  const lastSeen = deviceLastSeen[deviceId];
  if (!lastSeen) return 'offline';
  const ageMs = Date.now() - lastSeen.getTime();
  if (ageMs < STALE_THRESHOLD_MS) return 'online';
  if (ageMs < OFFLINE_THRESHOLD_MS) return 'stale';
  return 'offline';
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function severityFromGForce(gForce) {
  if (!gForce) return 'high';
  if (gForce >= 5.0) return 'critical';
  if (gForce >= 3.5) return 'high';
  if (gForce >= 2.5) return 'medium';
  return 'low';
}

function _sensorPayload(deviceId, t) {
  return {
    deviceId,
    timestamp: t.timestamp,
    accelerometerX: t.imu.ax,
    accelerometerY: t.imu.ay,
    accelerometerZ: t.imu.az,
    gyroscopeX: t.imu.gx,
    gyroscopeY: t.imu.gy,
    gyroscopeZ: t.imu.gz,
    accelMag: t.imu.accelMag,
    gyroMag: t.imu.gyroMag,
    speedKmph: t.speedKmph || 0,
  };
}

// ─── Health ────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(),
    uptime: process.uptime(), clients: io.engine.clientsCount });
});

// ─── POST /api/v1/telemetry ────────────────────────────────────────────────
app.post('/api/v1/telemetry', deviceAuth, (req, res) => {
  const body = req.body;
  const deviceId = body.deviceId || 'helmet-01';
  if (!body.imu) return res.status(400).json({ error: 'Missing imu field' });

  const now = new Date();
  deviceLastSeen[deviceId] = now;

  latestTelemetry[deviceId] = {
    deviceId,
    timestamp: body.timestamp || now.toISOString(),
    receivedAt: now.toISOString(),
    imu: body.imu,
    state: body.state || 'NORMAL',
    speedKmph: body.gps ? (body.gps.speedKmph || 0) : 0,
  };

  if (body.gps) {
    if (body.gps.fix) {
      latestGps[deviceId] = {
        deviceId,
        timestamp: body.gps.timestamp || now.toISOString(),
        receivedAt: now.toISOString(),
        fix: true,
        latitude: body.gps.latitude,
        longitude: body.gps.longitude,
        altitude: body.gps.altitude || 0,
        speedKmph: body.gps.speedKmph || 0,
        satellites: body.gps.satellites || 0,
      };
    } else if (!latestGps[deviceId]) {
      latestGps[deviceId] = { deviceId, timestamp: now.toISOString(), fix: false };
    }
  }

  // Track hardware state changes from telemetry
  const prevState = hardwareState[deviceId];
  const newState = body.state || 'NORMAL';
  if (prevState !== newState) {
    hardwareState[deviceId] = newState;
    io.emit('emergency.state', { deviceId, state: newState, timestamp: body.timestamp || now.toISOString() });
    console.log('[State]', deviceId, ':', prevState, '->', newState);
  }

  io.emit('sensor.update', _sensorPayload(deviceId, latestTelemetry[deviceId]));
  if (body.gps && body.gps.fix) io.emit('location.update', latestGps[deviceId]);
  io.emit('device.update', { deviceId, status: getDeviceStatus(deviceId), lastSeenAt: now.toISOString() });

  res.status(200).json({ ok: true, deviceId, receivedAt: now.toISOString() });
});

// ─── GET /api/v1/telemetry/latest ─────────────────────────────────────────
app.get('/api/v1/telemetry/latest', (req, res) => {
  const deviceId = req.query.deviceId || 'helmet-01';
  res.json({
    deviceId,
    telemetry: latestTelemetry[deviceId] || null,
    gps: latestGps[deviceId] || null,
    status: getDeviceStatus(deviceId),
    state: hardwareState[deviceId] || 'UNKNOWN',
  });
});

// ─── GET /api/v1/device/status ─────────────────────────────────────────────
app.get('/api/v1/device/status', (req, res) => {
  const deviceId = req.query.deviceId || 'helmet-01';
  res.json({
    deviceId,
    status: getDeviceStatus(deviceId),
    lastSeenAt: deviceLastSeen[deviceId] ? deviceLastSeen[deviceId].toISOString() : null,
    state: hardwareState[deviceId] || 'UNKNOWN',
  });
});

// ─── POST /api/v1/events ──────────────────────────────────────────────────
app.post('/api/v1/events', deviceAuth, (req, res) => {
  const body = req.body;
  const deviceId = body.deviceId || 'helmet-01';
  const event = body.event;
  const now = new Date();

  console.log('[Event]', deviceId, ':', event, '@', body.timestamp || now.toISOString());

  deviceLastSeen[deviceId] = now;

  if (body.gps && body.gps.fix) {
    latestGps[deviceId] = {
      deviceId,
      timestamp: body.gps.timestamp || now.toISOString(),
      receivedAt: now.toISOString(),
      fix: true,
      latitude: body.gps.latitude,
      longitude: body.gps.longitude,
      altitude: body.gps.altitude || 0,
      speedKmph: body.gps.speedKmph || 0,
      satellites: body.gps.satellites || 0,
    };
  }

  let newState = hardwareState[deviceId] || 'NORMAL';
  switch (event) {
    case 'CRASH_PENDING':       newState = 'CRASH_PENDING'; break;
    case 'EMERGENCY_CONFIRMED': newState = 'EMERGENCY_CONFIRMED'; break;
    case 'MANUAL_EMERGENCY':    newState = 'EMERGENCY_CONFIRMED'; break;
    case 'CANCEL':              newState = 'NORMAL'; break;
  }
  hardwareState[deviceId] = newState;

  io.emit('emergency.state', {
    deviceId, state: newState, event,
    timestamp: body.timestamp || now.toISOString(),
    gps: latestGps[deviceId] || null,
  });

  if (event === 'EMERGENCY_CONFIRMED' || event === 'MANUAL_EMERGENCY') {
    const gpsData = latestGps[deviceId];
    const imuData = body.imu || (latestTelemetry[deviceId] ? latestTelemetry[deviceId].imu : null);
    const peakGForce = imuData ? imuData.accelMag : null;
    const incidentId = 'inc-' + now.getTime();

    const incident = {
      id: incidentId,
      timestamp: body.timestamp || now.toISOString(),
      deviceId,
      location: gpsData && gpsData.fix ? {
        latitude: gpsData.latitude,
        longitude: gpsData.longitude,
        accuracy: 5.0,
        altitude: gpsData.altitude || 0,
        speed: gpsData.speedKmph ? gpsData.speedKmph / 3.6 : 0,
        heading: 0.0,
        timestamp: gpsData.timestamp,
      } : null,
      gpsFix: !!(gpsData && gpsData.fix),
      severity: severityFromGForce(peakGForce),
      status: 'open',
      crashConfidence: 0.98,
      metadata: {
        event,
        peakGForce,
        peakAngularVelocity: imuData ? imuData.gyroMag : null,
        trigger: event === 'MANUAL_EMERGENCY' ? 'Manual emergency button' : 'Hardware crash detection',
        gpsSource: gpsData && gpsData.fix ? 'real' : 'unavailable',
      },
    };

    incidents[incidentId] = incident;
    io.emit('incident.created', incident);
    io.emit('incident.dispatched', incident);
    console.log('[Incident] Created', incidentId, 'gpsFix:', incident.gpsFix);
  }

  res.status(200).json({ ok: true, deviceId, event, state: newState });
});

// ─── Incidents (existing API contract) ─────────────────────────────────────
app.post('/api/v1/incidents', (req, res) => {
  const body = req.body;
  if (!body.id) return res.status(400).json({ error: 'Missing id' });
  incidents[body.id] = body;
  io.emit('incident.created', body);
  res.status(201).json(body);
});

app.get('/api/v1/incidents', (req, res) => {
  const list = Object.values(incidents).sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
  res.json(list);
});

app.get('/api/v1/incidents/:id', (req, res) => {
  const inc = incidents[req.params.id];
  if (!inc) return res.status(404).json({ error: 'Not found' });
  res.json(inc);
});

app.put('/api/v1/incidents/:id', (req, res) => {
  const id = req.params.id;
  if (!incidents[id]) return res.status(404).json({ error: 'Not found' });
  incidents[id] = { ...incidents[id], ...req.body };
  io.emit('incident.updated', incidents[id]);
  res.json(incidents[id]);
});

// ─── Responders (existing API contract) ────────────────────────────────────
app.get('/api/v1/responders/nearest', (req, res) => {
  const lat = parseFloat(req.query.latitude || '0');
  const lon = parseFloat(req.query.longitude || '0');
  const radiusKm = parseFloat(req.query.radiusKm || '10');
  const type = req.query.type;
  const results = mockResponders
    .filter((r) => !type || r.type === type)
    .map((r) => ({ ...r, distanceKm: haversineKm(lat, lon, r.location.latitude, r.location.longitude) }))
    .filter((r) => r.distanceKm <= radiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm);
  res.json(results);
});

// ─── Start ─────────────────────────────────────────────────────────────────

// ─── Unified Emergency Contacts & Message API ────────────────────────────────
let contactsVersion = 1;
let emergencyMessage = "EMERGENCY: Rider has been involved in an accident! Location: {LOCATION} Speed: {SPEED}km/h";
let emergencyContacts = [
  { id: '1', name: 'Primary Contact', phoneNumber: '+917008072861', enabled: true }
];

app.get('/api/v1/contacts', (req, res) => {
  res.json({
    contactsVersion,
    messageTemplate: emergencyMessage,
    contacts: emergencyContacts
  });
});

app.post('/api/v1/contacts', (req, res) => {
  if (req.body.contacts && Array.isArray(req.body.contacts)) {
    emergencyContacts = req.body.contacts;
    contactsVersion++;
    io.emit('contacts.updated', { contactsVersion, messageTemplate: emergencyMessage, contacts: emergencyContacts });
    res.json({ ok: true, contactsVersion, contacts: emergencyContacts });
  } else {
    res.status(400).json({ error: 'Body must contain contacts array' });
  }
});

app.get('/api/v1/emergency-message', (req, res) => {
  res.json({ messageTemplate: emergencyMessage, contactsVersion });
});

app.put('/api/v1/emergency-message', (req, res) => {
  if (req.body.messageTemplate) {
    emergencyMessage = req.body.messageTemplate;
    contactsVersion++;
    io.emit('contacts.updated', { contactsVersion, messageTemplate: emergencyMessage, contacts: emergencyContacts });
    res.json({ ok: true, contactsVersion, messageTemplate: emergencyMessage });
  } else {
    res.status(400).json({ error: 'Missing messageTemplate' });
  }
});

server.listen(PORT, HOST, () => {
  console.log('\n🚑 RescueLink Backend running at http://' + HOST + ':' + PORT);
  console.log('   Health: http://' + HOST + ':' + PORT + '/health');
  console.log('   DEVICE_TOKEN:', DEVICE_TOKEN === 'change-me' ? '⚠️  change-me (default)' : '✅ configured');
  console.log('');
});

// Periodic device heartbeat broadcast (every 5 s)
setInterval(() => {
  for (const deviceId of Object.keys(deviceLastSeen)) {
    io.emit('device.update', {
      deviceId,
      status: getDeviceStatus(deviceId),
      lastSeenAt: deviceLastSeen[deviceId].toISOString(),
    });
  }
}, 5000);

