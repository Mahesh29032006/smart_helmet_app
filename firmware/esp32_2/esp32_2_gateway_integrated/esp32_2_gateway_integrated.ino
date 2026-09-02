#include <HardwareSerial.h>
#include <SoftwareSerial.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>   // You need this library installed in Arduino IDE
#include <Preferences.h>

Preferences preferences;
String dynamicPhone = "+917008072861"; // Default fallback
// ============================================================
// CONFIGURATION: WIFI & BACKEND
// ============================================================
const char* WIFI_SSID     = "AMAN'S VIVO";
const char* WIFI_PASSWORD = "A0000000";

const char* SERVER_URL    = "http://172.21.73.191:5001/api/v1";
const char* DEVICE_ID     = "helmet-01";
const char* DEVICE_TOKEN  = "change-me";

// ============================================================
// ESP32 #2 - SMART HELMET GATEWAY
// ============================================================

// ============================================================
// GPS
// ============================================================
SoftwareSerial GPS;
#define GPS_RX 16
#define GPS_TX 17
#define GPS_BAUD 9600

// ============================================================
// LTE
// ============================================================
HardwareSerial LTE(1);
#define LTE_RX 18
#define LTE_TX 19
#define LTE_BAUD 115200

// ============================================================
// ESP1 LINK
// ============================================================
HardwareSerial LINK(2);
#define LINK_RX 27
#define LINK_TX 26
#define LINK_BAUD 115200

// ============================================================
// SMS RECIPIENT
// ============================================================
// --- Dynamic Contacts (Max 10) ---
int contactsVersion = 0;
int contactCount = 1;
String contactPhones[10] = {"+917008072861"};
String messageTemplate = "EMERGENCY: Crash detected! Location: {LOCATION}";

// ============================================================
// GPS & SENSOR STATE
// ============================================================
String gpsLine = "";
bool gpsFix = false;
int satellites = 0;
double latitude = 0.0;
double longitude = 0.0;
double altitude = 0.0;
double speedKmph = 0.0;
String gpsDate = "";
String gpsTime = "";
unsigned long gpsCharacters = 0;
unsigned long lastValidGPS = 0;
unsigned long lastGPSDisplay = 0;

float esp1AX = 0.0;
float esp1AY = 0.0;
float esp1AZ = 0.0;
float esp1GX = 0.0;
float esp1GY = 0.0;
float esp1GZ = 0.0;
float esp1Accel = 0.0;
float esp1Gyro = 0.0;

unsigned long lastESP1Data = 0;
bool smsSentForCurrentEmergency = false;

// ─── Backend State ──────────────────────────────────────────
String currentEmergencyState = "NORMAL";
unsigned long lastTelemetryTime = 0;
unsigned long lastWifiCheckTime = 0;
const unsigned long TELEMETRY_INTERVAL = 1000;

// ============================================================
// HELPER FUNCTIONS (GPS, LTE) - SAME AS ORIGINAL
// ============================================================
double nmeaToDecimal(String value, String direction) {
  if (value.length() == 0) return 0.0;
  double raw = value.toDouble();
  int degrees = (int)(raw / 100.0);
  double minutes = raw - degrees * 100.0;
  double result = degrees + minutes / 60.0;
  if (direction == "S" || direction == "W") result = -result;
  return result;
}

int splitNMEA(String line, String fields[], int maximum) {
  int count = 0;
  int start = 0;
  for (int i = 0; i <= line.length(); i++) {
    if (i == line.length() || line[i] == ',') {
      if (count < maximum) {
        fields[count++] = line.substring(start, i);
      }
      start = i + 1;
    }
  }
  return count;
}

void parseGPS(String line) {
  line.trim();
  if (!line.startsWith("$")) return;

  if (line.startsWith("$GNRMC") || line.startsWith("$GPRMC")) {
    String f[13];
    if (splitNMEA(line, f, 13) < 10) return;
    gpsTime = f[1];
    if (f[2] == "A") {
      gpsFix = true;
      latitude = nmeaToDecimal(f[3], f[4]);
      longitude = nmeaToDecimal(f[5], f[6]);
      if (f[7].length() > 0) speedKmph = f[7].toDouble() * 1.852;
      gpsDate = f[9];
      lastValidGPS = millis();
    } else {
      gpsFix = false;
    }
  }

  if (line.startsWith("$GNGGA") || line.startsWith("$GPGGA")) {
    String f[15];
    if (splitNMEA(line, f, 15) < 10) return;
    if (f[6].length() > 0) gpsFix = f[6].toInt() > 0;
    if (f[7].length() > 0) satellites = f[7].toInt();
    if (f[9].length() > 0) altitude = f[9].toDouble();
    if (gpsFix) lastValidGPS = millis();
  }
}

void readGPS() {
  while (GPS.available()) {
    char c = GPS.read();
    gpsCharacters++;
    if (c == '\n') {
      parseGPS(gpsLine);
      gpsLine = "";
    } else if (c != '\r') {
      gpsLine += c;
      if (gpsLine.length() > 200) gpsLine = "";
    }
  }
  if (gpsFix && millis() - lastValidGPS > 5000) {
    gpsFix = false;
  }
}

// ============================================================
// HTTP BACKEND INTEGRATION
// ============================================================
String getIsoTimestamp() {
  return "2026-09-02T00:00:00.000Z";
}

String buildJsonPayload(String type, String stateParam) {
  String json = "{";
  json += "\"version\": 1,";
  json += "\"deviceId\": \"" + String(DEVICE_ID) + "\",";
  
  if (type == "event") {
    json += "\"event\": \"" + stateParam + "\",";
  } else {
    json += "\"state\": \"" + stateParam + "\",";
  }
  
  json += "\"imu\": {";
  json += "\"ax\": " + String(esp1AX, 3) + ",";
  json += "\"ay\": " + String(esp1AY, 3) + ",";
  json += "\"az\": " + String(esp1AZ, 3) + ",";
  json += "\"gx\": " + String(esp1GX, 3) + ",";
  json += "\"gy\": " + String(esp1GY, 3) + ",";
  json += "\"gz\": " + String(esp1GZ, 3) + ",";
  json += "\"accelMag\": " + String(esp1Accel, 3) + ",";
  json += "\"gyroMag\": " + String(esp1Gyro, 3);
  json += "}";
  
  if (gpsFix) {
    json += ",\"gps\": {";
    json += "\"fix\": true,";
    json += "\"latitude\": " + String(latitude, 6) + ",";
    json += "\"longitude\": " + String(longitude, 6) + ",";
    json += "\"altitude\": " + String(altitude, 1) + ",";
    json += "\"speedKmph\": " + String(speedKmph, 1) + ",";
    json += "\"satellites\": " + String(satellites) + ",";
    json += "\"timestamp\": \"" + getIsoTimestamp() + "\"";
    json += "}";
  }
  
  json += "}";
  return json;
}

void sendTelemetry() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/telemetry";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Token", DEVICE_TOKEN);
  
  String payload = buildJsonPayload("telemetry", currentEmergencyState);
  int httpCode = http.POST(payload);
  
  if (httpCode > 0) {
    Serial.printf("[HTTP] Telemetry POST... code: %d\n", httpCode);
  } else {
    Serial.printf("[HTTP] Telemetry POST... failed, error: %s\n", http.errorToString(httpCode).c_str());
  }
  
  http.end();
}

void sendEmergencyEvent(String newState) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[WARNING] Cannot send Event to App: WiFi Not Connected!");
    return;
  }
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/events";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Token", DEVICE_TOKEN);
  
  String payload = buildJsonPayload("event", newState);
  int httpCode = http.POST(payload);
  Serial.printf("[HTTP] Event %s POST... code: %d\n", newState.c_str(), httpCode);
  http.end();
}

// ============================================================
// LTE / SMS
// ============================================================
String lteRead(unsigned long timeout) {
  String response = "";
  unsigned long start = millis();
  while (millis() - start < timeout) {
    while (LTE.available()) {
      char c = LTE.read();
      response += c;
    }
  }
  return response;
}

String sendAT(const char *command, unsigned long timeout = 3000) {
  while (LTE.available()) LTE.read();
  LTE.print(command);
  LTE.print("\r\n");
  return lteRead(timeout);
}

bool sendEmergencySMS() {
  Serial.println("Starting Unified Dual-SMS routine via A7672S...");
  
  String finalMsg = messageTemplate;
  String locStr = gpsFix ? "https://maps.google.com/?q=" + String(latitude, 6) + "," + String(longitude, 6) : "Unknown Location";
  finalMsg.replace("{LOCATION}", locStr);
  finalMsg.replace("{LATITUDE}", gpsFix ? String(latitude, 6) : "N/A");
  finalMsg.replace("{LONGITUDE}", gpsFix ? String(longitude, 6) : "N/A");
  finalMsg.replace("{SPEED}", gpsFix ? String(speedKmph, 1) : "N/A");
  finalMsg.replace("{ALTITUDE}", gpsFix ? String(altitude, 1) : "N/A");
  finalMsg.replace("{SATELLITES}", String(satellites));
  finalMsg.replace("{TIME}", "N/A");
  
  bool anySuccess = false;
  for (int i = 0; i < contactCount; i++) {
    String currentPhone = contactPhones[i];
    if (currentPhone.length() < 3) continue;

    Serial.print("Sending SMS to: ");
    Serial.println(currentPhone);

    while (LTE.available()) LTE.read();
    LTE.println("AT+CMGF=1");
    delay(100);
    
    LTE.print("AT+CMGS=\"");
    LTE.print(currentPhone);
    LTE.print("\"\r");
    delay(100);
    
    LTE.print(finalMsg);
    LTE.write(26); // CTRL+Z
    
    unsigned long start = millis();
    String result = "";
    bool thisSuccess = false;
    while (millis() - start < 10000) {
      while (LTE.available()) {
        result += (char)LTE.read();
      }
      if (result.indexOf("+CMGS") >= 0 || result.indexOf("OK") >= 0) {
        thisSuccess = true;
        anySuccess = true;
        break;
      }
      if (result.indexOf("ERROR") >= 0) break;
    }
    
    if (thisSuccess) {
      Serial.println("SMS SENT SUCCESSFULLY to " + currentPhone);
    } else {
      Serial.println("SMS FAILED to " + currentPhone);
    }
    delay(1000); // Small pause between texts
  }
  
  return anySuccess;
}

// ============================================================
// PARSE ESP1 DATA
// ============================================================
void parseSensorPacket(String message) {
  String f[10];
  if (splitNMEA(message, f, 10) < 9) return;
  
  esp1AX = f[1].toFloat();
  esp1AY = f[2].toFloat();
  esp1AZ = f[3].toFloat();
  esp1GX = f[4].toFloat();
  esp1GY = f[5].toFloat();
  esp1GZ = f[6].toFloat();
  esp1Accel = f[7].toFloat();
  esp1Gyro = f[8].toFloat();
  
  lastESP1Data = millis();
}

void readESP1() {
  static String message = "";
  while (LINK.available()) {
    char c = LINK.read();
    if (c == '\n') {
      message.trim();
      if (message.length() == 0) continue;

      if (message.startsWith("SENSOR,")) {
        parseSensorPacket(message);
      }
      else if (message == "CRASH_PENDING") {
        currentEmergencyState = "CRASH_PENDING";
        sendEmergencyEvent("CRASH_PENDING");
      }
      else if (message == "MANUAL_EMERGENCY") {
        currentEmergencyState = "CRASH_PENDING";
        sendEmergencyEvent("MANUAL_EMERGENCY");
      }
      else if (message == "EMERGENCY_CONFIRMED") {
        currentEmergencyState = "EMERGENCY_CONFIRMED";
        sendEmergencyEvent("EMERGENCY_CONFIRMED");
        if (!smsSentForCurrentEmergency) {
          if (sendEmergencySMS()) {
            smsSentForCurrentEmergency = true;
            LINK.println("SMS_SENT");
          } else {
            LINK.println("SMS_FAILED");
          }
        }
      }
      else if (message == "CANCEL") {
        currentEmergencyState = "NORMAL";
        sendEmergencyEvent("CANCEL");
        smsSentForCurrentEmergency = false;
      }

      message = "";
    } else {
      message += c;
      if (message.length() > 300) message = "";
    }
  }
}

// ============================================================
// SETUP
// ============================================================

void fetchDynamicContacts() {
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Checking for contact updates from Backend...");
    HTTPClient http;
    http.begin(String(SERVER_URL) + "/contacts");
    int httpCode = http.GET();
    if (httpCode == 200) {
      String payload = http.getString();
      DynamicJsonDocument doc(4096);
      DeserializationError error = deserializeJson(doc, payload);
      if (!error) {
        int newVersion = doc["contactsVersion"] | 0;
        if (newVersion > contactsVersion) {
          Serial.println("New contacts configuration found! Updating EEPROM...");
          contactsVersion = newVersion;
          messageTemplate = doc["messageTemplate"].as<String>();
          
          JsonArray arr = doc["contacts"].as<JsonArray>();
          contactCount = 0;
          for (JsonVariant v : arr) {
            if (contactCount >= 10) break;
            bool enabled = v["enabled"] | true;
            if (enabled) {
              contactPhones[contactCount] = v["phoneNumber"].as<String>();
              contactCount++;
            }
          }
          
          preferences.begin("rescue_config", false);
          preferences.putInt("version", contactsVersion);
          preferences.putInt("count", contactCount);
          preferences.putString("msgTemp", messageTemplate);
          for (int i = 0; i < contactCount; i++) {
            preferences.putString(("phone" + String(i)).c_str(), contactPhones[i]);
          }
          preferences.end();
          Serial.println("Contacts successfully synced to Hardware EEPROM.");
        }
      }
    }
    http.end();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n========================================");
  Serial.println("ESP32 #2 GATEWAY - INITIALIZING");
  Serial.println("========================================");
  
  GPS.begin(GPS_BAUD, SWSERIAL_8N1, GPS_RX, GPS_TX);
  LTE.begin(LTE_BAUD, SERIAL_8N1, LTE_RX, LTE_TX);
  LINK.begin(LINK_BAUD, SERIAL_8N1, LINK_RX, LINK_TX);
  
  // Connect WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 10) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[SUCCESS] Connected to WiFi! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n[ERROR] Failed to connect to WiFi! Make sure Hotspot is 2.4GHz!");
  }
  
  sendAT("AT");
  sendAT("ATE0");
  Serial.println("ESP32 #2 READY");
}

// ============================================================
// LOOP
// ============================================================
void loop() {
  readGPS();
  readESP1();
  
  unsigned long now = millis();
  
  // Check WiFi status periodically
  if (now - lastWifiCheckTime >= 5000) {
    lastWifiCheckTime = now;
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[WARNING] WiFi Disconnected! Trying to reconnect...");
      WiFi.reconnect();
    }
  }
  
  // Send HTTP Telemetry periodically
  if (now - lastTelemetryTime >= TELEMETRY_INTERVAL) {
    lastTelemetryTime = now;
    if (WiFi.status() == WL_CONNECTED) {
      sendTelemetry(); // Sends JSON over WiFi to Node.js backend
    }
  }
}
