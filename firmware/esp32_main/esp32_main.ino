#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>   // You need this library installed in Arduino IDE
#include <Preferences.h>

Preferences preferences;
String dynamicPhone = "+917008072861"; // Default fallback
// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════
const char* WIFI_SSID     = "AMAN'S VIVO";
const char* WIFI_PASSWORD = "A0000000";

// The Node.js backend URL for telemetry ingestion
// Example: "http://192.168.1.100:5000/api/v1"
const char* SERVER_URL    = "http://172.21.73.191:5001/api/v1";

const char* DEVICE_ID     = "helmet-01";
const char* DEVICE_TOKEN  = "change-me";

// ═══════════════════════════════════════════════════════════════════════════
// HARDWARE PINS (Based on Existing Documentation)
// ═══════════════════════════════════════════════════════════════════════════
// ESP32 #1 ↔ ESP32 #2 UART LINK
#define RX_PIN 27 // Connected to ESP1 TX (GPIO32)
#define TX_PIN 26 // Connected to ESP1 RX (GPIO34)

// GPS Module (M8N)
#define GPS_RX 16
#define GPS_TX 17

// LTE Module (A7672S)
#define LTE_RX 18
#define LTE_TX 19

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL STATE
// ═══════════════════════════════════════════════════════════════════════════
unsigned long lastTelemetryTime = 0;
const unsigned long TELEMETRY_INTERVAL = 1000; // 1 second

// Mocking some state variables that would normally be populated by UART from ESP32 #1
String currentEmergencyState = "NORMAL";
float currentAx = 0.0;
float currentAy = 0.0;
float currentAz = 1.0;
float currentGx = 0.0;
float currentGy = 0.0;
float currentGz = 0.0;
float currentAccelMag = 1.0;
float currentGyroMag = 0.0;

// Mocking GPS state
bool gpsHasFix = true;
float currentLat = 22.252728;
float currentLon = 84.913810;
float currentAlt = 217.9;
float currentSpeedKmph = 0.0;
int currentSatellites = 8;
String currentGpsTimestamp = "2026-08-31T18:20:00.000Z";

void setup() {
  Serial.begin(115200);
  
  // Initialize Serial for ESP1 communication
  Serial1.begin(115200, SERIAL_8N1, RX_PIN, TX_PIN);
  
  // Initialize Serial for GPS
  Serial2.begin(9600, SERIAL_8N1, GPS_RX, GPS_TX);
  
  // Initialize WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("Connecting to WiFi...");
  
  // Note: We don't block forever waiting for WiFi.
  // The loop will handle intermittent connectivity.
}

void loop() {
  // 1. Process incoming UART data from ESP32 #1 (IMU & Crash Events)
  processEsp1Data();
  
  // 2. Process incoming GPS data
  processGpsData();
  
  // 3. Process LTE/SMS logic
  processLteData();
  
  // 4. Send Telemetry at interval
  unsigned long now = millis();
  if (now - lastTelemetryTime >= TELEMETRY_INTERVAL) {
    lastTelemetryTime = now;
    sendTelemetry();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA PROCESSING (Stubs representing existing logic)
// ═══════════════════════════════════════════════════════════════════════════
void processEsp1Data() {
  // In a real scenario, this would parse incoming UART packets from ESP32 #1
  // and update currentAx, currentAy, currentEmergencyState, etc.
}

void processGpsData() {
  // In a real scenario, this would parse NMEA sentences from Serial2
  // and update currentLat, currentLon, gpsHasFix, etc.
}

void processLteData() {
  // In a real scenario, this handles incoming SMS and network status via AT commands
}

// ═══════════════════════════════════════════════════════════════════════════
// HTTP COMMUNICATION
// ═══════════════════════════════════════════════════════════════════════════
void sendTelemetry() {
  if (WiFi.status() != WL_CONNECTED) {
    // If not connected, we skip HTTP but local hardware operation continues
    return;
  }
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/telemetry";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Token", DEVICE_TOKEN);
  
  String payload = buildJsonPayload("telemetry", currentEmergencyState);
  
  int httpResponseCode = http.POST(payload);
  
  if (httpResponseCode > 0) {
    // Success or expected HTTP error
    // Serial.printf("HTTP Response code: %d\n", httpResponseCode);
  } else {
    // Connection error
    // Serial.printf("HTTP POST failed, error: %s\n", http.errorToString(httpResponseCode).c_str());
  }
  
  http.end();
}

void sendEmergencyEvent(String newState) {
  // Called immediately when emergency state changes (e.g., NORMAL -> CRASH_PENDING)
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/events";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Token", DEVICE_TOKEN);
  
  String payload = buildJsonPayload("event", newState);
  
  int httpResponseCode = http.POST(payload);
  
  if (httpResponseCode > 0) {
    // Serial.printf("Event POST Response: %d\n", httpResponseCode);
  }
  
  http.end();
}

String buildJsonPayload(String type, String state) {
  // Building JSON manually for simplicity in firmware
  String json = "{";
  json += "\"version\": 1,";
  json += "\"deviceId\": \"" + String(DEVICE_ID) + "\",";
  
  if (type == "event") {
    json += "\"event\": \"" + state + "\",";
  } else {
    json += "\"state\": \"" + state + "\",";
  }
  
  json += "\"imu\": {";
  json += "\"ax\": " + String(currentAx, 3) + ",";
  json += "\"ay\": " + String(currentAy, 3) + ",";
  json += "\"az\": " + String(currentAz, 3) + ",";
  json += "\"gx\": " + String(currentGx, 3) + ",";
  json += "\"gy\": " + String(currentGy, 3) + ",";
  json += "\"gz\": " + String(currentGz, 3) + ",";
  json += "\"accelMag\": " + String(currentAccelMag, 3) + ",";
  json += "\"gyroMag\": " + String(currentGyroMag, 3);
  json += "},";
  
  json += "\"gps\": {";
  json += "\"fix\": " + String(gpsHasFix ? "true" : "false") + ",";
  json += "\"latitude\": " + String(currentLat, 6) + ",";
  json += "\"longitude\": " + String(currentLon, 6) + ",";
  json += "\"altitude\": " + String(currentAlt, 1) + ",";
  json += "\"speedKmph\": " + String(currentSpeedKmph, 1) + ",";
  json += "\"satellites\": " + String(currentSatellites) + ",";
  json += "\"timestamp\": \"" + currentGpsTimestamp + "\"";
  json += "}";
  json += "}";
  
  return json;
}
