#include <Wire.h>
#include <HardwareSerial.h>
#include <math.h>
#include <ArduinoJson.h>   // You need this library installed in Arduino IDE
#include <Preferences.h>

Preferences preferences;
String dynamicPhone = "+917008072861"; // Default fallback
// ============================================================
// ESP32 #1 - SMART HELMET
//
// MPU6500 + BUTTON + BUZZER + LED
//
// ESP1 GPIO32 TX -> ESP2 GPIO27 RX
// ESP1 GPIO34 RX <- ESP2 GPIO26 TX
//
// LINK BAUD = 115200
// ============================================================

// ============================================================
// MPU6500
// ============================================================
#define MPU_SDA   21
#define MPU_SCL   22
#define MPU_ADDR  0x68

// ============================================================
// ESP1 <-> ESP2 LINK
// ============================================================
#define LINK_TX   32
#define LINK_RX   34
#define LINK_BAUD 115200

HardwareSerial LINK(1);

// ============================================================
// DEVICES
// ============================================================
#define BUTTON_PIN 25
#define BUZZER_PIN 23
#define LED_PIN     2

// ============================================================
// MPU VALUES
// ============================================================
float ax = 0.0f;
float ay = 0.0f;
float az = 0.0f;

float gx = 0.0f;
float gy = 0.0f;
float gz = 0.0f;

float accelMag = 0.0f;
float gyroMag = 0.0f;

// ============================================================
// MPU SCALE
// ============================================================
const float ACCEL_SCALE = 4096.0f;
const float GYRO_SCALE  = 16.4f;

// ============================================================
// CRASH THRESHOLDS
// ============================================================
const float HARD_IMPACT_G = 4.0f;
const float COMBINED_IMPACT_G = 2.5f;
const float COMBINED_GYRO_DPS = 350.0f;

// ============================================================
// TIMING
// ============================================================
const unsigned long CANCEL_WINDOW_MS = 10000UL;
const unsigned long REARM_DELAY_MS = 5000UL;
const unsigned long SENSOR_INTERVAL_MS = 50UL;
const unsigned long TELEMETRY_INTERVAL_MS = 1000UL;
const unsigned long DISPLAY_INTERVAL_MS = 2000UL;

// ============================================================
// EMERGENCY STATES
// ============================================================
enum EmergencyState
{
  EMERGENCY_NORMAL,
  EMERGENCY_PENDING,
  EMERGENCY_CONFIRMED
};

EmergencyState state = EMERGENCY_NORMAL;
bool crashEvent = false;
unsigned long emergencyStart = 0;
unsigned long rearmAt = 0;

// ============================================================
// BUTTON
// ============================================================
const unsigned long BUTTON_DEBOUNCE_MS = 40UL;
const unsigned long MANUAL_LONG_PRESS_MS = 2000UL;

bool buttonRaw = HIGH;
bool buttonStable = HIGH;
unsigned long buttonChangeTime = 0;
unsigned long buttonPressStart = 0;
bool longPressHandled = false;
bool manualEmergencyAwaitingNextPress = false;

// ============================================================
// TIMERS
// ============================================================
unsigned long lastSensorRead = 0;
unsigned long lastTelemetry = 0;
unsigned long lastDisplay = 0;

// ============================================================
// MPU WRITE/READ
// ============================================================
void writeMPU(byte reg, byte value)
{
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
}

byte readMPU(byte reg)
{
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return 0;
  Wire.requestFrom(MPU_ADDR, 1);
  if (Wire.available()) return Wire.read();
  return 0;
}

bool readMPUData()
{
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(MPU_ADDR, 14) != 14) return false;

  int16_t axRaw = ((int16_t)Wire.read() << 8) | Wire.read();
  int16_t ayRaw = ((int16_t)Wire.read() << 8) | Wire.read();
  int16_t azRaw = ((int16_t)Wire.read() << 8) | Wire.read();

  Wire.read();
  Wire.read();

  int16_t gxRaw = ((int16_t)Wire.read() << 8) | Wire.read();
  int16_t gyRaw = ((int16_t)Wire.read() << 8) | Wire.read();
  int16_t gzRaw = ((int16_t)Wire.read() << 8) | Wire.read();

  ax = axRaw / ACCEL_SCALE;
  ay = ayRaw / ACCEL_SCALE;
  az = azRaw / ACCEL_SCALE;

  gx = gxRaw / GYRO_SCALE;
  gy = gyRaw / GYRO_SCALE;
  gz = gzRaw / GYRO_SCALE;

  accelMag = sqrtf(ax * ax + ay * ay + az * az);
  gyroMag = sqrtf(gx * gx + gy * gy + gz * gz);

  return true;
}

bool initMPU()
{
  Wire.begin(MPU_SDA, MPU_SCL);
  delay(100);
  byte who = readMPU(0x75);
  Serial.print("MPU WHO_AM_I = 0x");
  Serial.println(who, HEX);

  if (who != 0x70 && who != 0x71 && who != 0x73) {
    Serial.println("ERROR: MPU6500 NOT DETECTED");
    return false;
  }

  writeMPU(0x6B, 0x00);
  delay(100);
  writeMPU(0x1C, 0x10);
  writeMPU(0x1B, 0x18);
  Serial.println("MPU6500 OK");
  return true;
}

// ============================================================
// SEND TELEMETRY
// ============================================================
void sendTelemetry()
{
  LINK.print("SENSOR,");
  LINK.print(ax, 3);
  LINK.print(",");
  LINK.print(ay, 3);
  LINK.print(",");
  LINK.print(az, 3);
  LINK.print(",");
  LINK.print(gx, 2);
  LINK.print(",");
  LINK.print(gy, 2);
  LINK.print(",");
  LINK.print(gz, 2);
  LINK.print(",");
  LINK.print(accelMag, 3);
  LINK.print(",");
  LINK.print(gyroMag, 2);
  LINK.println();
}

// ============================================================
// START CRASH
// ============================================================
void startCrash()
{
  if (state != EMERGENCY_NORMAL) return;
  if (millis() < rearmAt) return;

  state = EMERGENCY_PENDING;
  crashEvent = true;
  manualEmergencyAwaitingNextPress = false;
  emergencyStart = millis();

  Serial.println("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  Serial.println("         CRASH DETECTED");
  Serial.println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  Serial.print("Acceleration = ");
  Serial.print(accelMag, 3);
  Serial.println(" g");
  Serial.print("Gyro = ");
  Serial.print(gyroMag, 2);
  Serial.println(" dps");
  Serial.println("10-second cancellation window started.");

  LINK.println("CRASH_PENDING");
}

// ============================================================
// START MANUAL EMERGENCY
// ============================================================
void startManualEmergency()
{
  if (state != EMERGENCY_NORMAL) return;
  if (millis() < rearmAt) return;

  state = EMERGENCY_PENDING;
  crashEvent = false;
  manualEmergencyAwaitingNextPress = true;
  emergencyStart = millis();

  Serial.println("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  Serial.println("       MANUAL EMERGENCY");
  Serial.println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  Serial.println("10-second cancellation window started.");

  LINK.println("MANUAL_EMERGENCY");
}

// ============================================================
// CANCEL
// ============================================================
void cancelEmergency()
{
  if (state == EMERGENCY_NORMAL) return;
  state = EMERGENCY_NORMAL;
  crashEvent = false;
  manualEmergencyAwaitingNextPress = false;
  rearmAt = millis() + REARM_DELAY_MS;

  noTone(BUZZER_PIN);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  Serial.println("\n================================");
  Serial.println("       EMERGENCY CANCELLED");
  Serial.println("================================");

  LINK.println("CANCEL");
}

// ============================================================
// CONFIRM
// ============================================================
void confirmEmergency()
{
  if (state != EMERGENCY_PENDING) return;
  state = EMERGENCY_CONFIRMED;

  Serial.println("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  Serial.println("      EMERGENCY CONFIRMED");
  Serial.println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

  LINK.println("EMERGENCY_CONFIRMED");
}

// ============================================================
// BUTTON
// ============================================================
void checkButton()
{
  bool reading = digitalRead(BUTTON_PIN);

  if (reading != buttonRaw) {
    buttonRaw = reading;
    buttonChangeTime = millis();
  }

  if (millis() - buttonChangeTime < BUTTON_DEBOUNCE_MS) return;

  if (reading != buttonStable) {
    buttonStable = reading;

    if (buttonStable == LOW) {
      buttonPressStart = millis();
      longPressHandled = false;

      if ((state == EMERGENCY_PENDING || state == EMERGENCY_CONFIRMED) &&
          !manualEmergencyAwaitingNextPress) {
        cancelEmergency();
        return;
      }
    } else {
      if (manualEmergencyAwaitingNextPress) {
        manualEmergencyAwaitingNextPress = false;
      }
      buttonPressStart = 0;
    }
  }

  if (buttonStable == LOW && !longPressHandled && state == EMERGENCY_NORMAL &&
      millis() - buttonPressStart >= MANUAL_LONG_PRESS_MS) {
    longPressHandled = true;
    startManualEmergency();
  }
}

// ============================================================
// CRASH CONDITION
// ============================================================
void checkCrash()
{
  if (state != EMERGENCY_NORMAL) return;
  if (millis() < rearmAt) return;

  bool hardImpact = accelMag >= HARD_IMPACT_G;
  bool combinedImpact = accelMag >= COMBINED_IMPACT_G && gyroMag >= COMBINED_GYRO_DPS;

  if (hardImpact || combinedImpact) {
    startCrash();
  }
}

// ============================================================
// LED + BUZZER
// ============================================================
void updateEmergencyOutputs()
{
  if (state == EMERGENCY_NORMAL) {
    digitalWrite(LED_PIN, LOW);
    noTone(BUZZER_PIN);
    digitalWrite(BUZZER_PIN, LOW);
    return;
  }

  if (state == EMERGENCY_PENDING) {
    digitalWrite(LED_PIN, ((millis() / 150) % 2));
    unsigned long phase = millis() % 600;
    if (phase < 300) {
      tone(BUZZER_PIN, 3000);
    } else {
      noTone(BUZZER_PIN);
    }
    if (millis() - emergencyStart >= CANCEL_WINDOW_MS) {
      confirmEmergency();
    }
    return;
  }

  if (state == EMERGENCY_CONFIRMED) {
    digitalWrite(LED_PIN, ((millis() / 100) % 2));
    unsigned long phase = millis() % 800;
    if (phase < 500) {
      tone(BUZZER_PIN, 3200);
    } else {
      noTone(BUZZER_PIN);
    }
  }
}

// ============================================================
// READ ESP2
// ============================================================
void readESP2()
{
  static String incoming = "";
  while (LINK.available()) {
    char c = LINK.read();
    if (c == '\n') {
      incoming.trim();
      if (incoming.length()) {
        Serial.print("ESP2 >> ");
        Serial.println(incoming);
      }
      incoming = "";
    } else {
      incoming += c;
      if (incoming.length() > 200) incoming = "";
    }
  }
}

// ============================================================
// SETUP
// ============================================================
void setup()
{
  Serial.begin(115200);
  delay(2000);

  Serial.println("\n==============================================");
  Serial.println("        SMART HELMET - ESP32 #1");
  Serial.println("==============================================");

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  LINK.begin(LINK_BAUD, SERIAL_8N1, LINK_RX, LINK_TX);
  
  if (initMPU()) {
    Serial.println("MPU READY");
  } else {
    Serial.println("MPU FAILED");
  }

  Serial.println("ESP32 #1 READY");
}

// ============================================================
// LOOP
// ============================================================
void loop()
{
  checkButton();

  if (millis() - lastSensorRead >= SENSOR_INTERVAL_MS) {
    lastSensorRead = millis();
    if (readMPUData()) {
      checkCrash();
    }
  }

  if (millis() - lastTelemetry >= TELEMETRY_INTERVAL_MS) {
    lastTelemetry = millis();
    sendTelemetry();
  }

  updateEmergencyOutputs();
  readESP2();

  if (millis() - lastDisplay >= DISPLAY_INTERVAL_MS) {
    lastDisplay = millis();
    Serial.println("\n--------------- ESP1 ---------------");
    Serial.print("|A| = ");
    Serial.print(accelMag, 3);
    Serial.println(" g");
    Serial.print("STATE = ");
    if (state == EMERGENCY_NORMAL) Serial.println("NORMAL");
    else if (state == EMERGENCY_PENDING) Serial.println("PENDING");
    else Serial.println("CONFIRMED");
  }
}
