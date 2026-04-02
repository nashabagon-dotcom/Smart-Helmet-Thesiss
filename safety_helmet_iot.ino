/*
 * Program ID: safety_helmet_iot.INO
 * Program by: 
 *             
 *    Version: 1.0
 *
 *        MCU: Waveshare ESP32 S3 Zero
 *
 *    Details:
 *
 *             PIN ASSIGNMENTS:
 *                 GPIO 4  - AM2302 (DHT22) Data
 *                 GPIO 8  - MPU6050 SDA
 *                 GPIO 9  - MPU6050 SCL
 *                 GPIO 12 - Buzzer
 *                 GPIO 17 - GPS NEO-6M RX (ESP32 RX <- GPS TX)
 *                 GPIO 18 - GPS NEO-6M TX (ESP32 TX -> GPS RX)
 *                 GPIO 21 - WS2812 RGB LED
 *
 *             LIBRARIES REQUIRED:
 *                 DHT sensor library (Adafruit)
 *                 Adafruit Unified Sensor
 *                 MPU6050 by Electronic Cats
 *                 TinyGPSPlus by Mikal Hart
 *                 Adafruit NeoPixel
 *                 ArduinoJson by Benoit Blanchon
 *                 Firebase ESP Client by Mobizt
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <DHT.h>
#include <Wire.h>
#include <MPU6050.h>
#include <TinyGPSPlus.h>
#include <Adafruit_NeoPixel.h>
#include <math.h>
#include <time.h>

// ============================================================
// WIFI CREDENTIALS
// ============================================================
#define WIFI_SSID      "safetyhelmetiot"
#define WIFI_PASSWORD  "safetyhelmet2026"

// ============================================================
// FIREBASE CREDENTIALS
// ============================================================
#define API_KEY        "AIzaSyBObItlAdigV3Bd5YISWDhHAeptYc3F7x0"
#define DATABASE_URL   "https://safetyhelmetiot-3dfeb-default-rtdb.firebaseio.com"

// ============================================================
// HELMET ID - Change for each helmet
// ============================================================
#define HELMET_ID      "HELMET_001"

// ============================================================
// PIN DEFINITIONS
// ============================================================
#define DHT_PIN        4
#define DHT_TYPE       DHT22
#define SDA_PIN        8
#define SCL_PIN        9
#define BUZZER_PIN     12
#define GPS_RX_PIN     17
#define GPS_TX_PIN     18
#define LED_PIN        21
#define NUM_LEDS       1

// ============================================================
// OBJECTS
// ============================================================
DHT               dht(DHT_PIN, DHT_TYPE);
MPU6050           mpu;
TinyGPSPlus       gps;
HardwareSerial    gpsSerial(1);
Adafruit_NeoPixel pixel(NUM_LEDS, LED_PIN, NEO_GRB + NEO_KHZ800);
FirebaseData      fbdo;
FirebaseData      fbdoSettings;
FirebaseAuth      auth;
FirebaseConfig    config;

// ============================================================
// SENSOR DATA
// ============================================================
float   temperature = 0.0;
float   humidity    = 0.0;
float   accelX      = 0.0;
float   accelY      = 0.0;
float   accelZ      = 0.0;
float   gyroX       = 0.0;
float   gyroY       = 0.0;
float   gyroZ       = 0.0;
float   gForce      = 1.0;
double  latitude    = 0.0;
double  longitude   = 0.0;
int     satellites  = 0;
bool    gpsValid    = false;
bool    fallen      = false;

// ============================================================
// THRESHOLDS (loaded from Firebase /settings/thresholds)
// ============================================================
float tempThreshold   = 35.0;
float gforceThreshold = 2.5;

// ============================================================
// TIMING
// ============================================================
unsigned long lastUpdate      = 0;
unsigned long lastThreshFetch = 0;
const long    UPDATE_INTERVAL = 5000;   // 5 seconds
const long    THRESH_INTERVAL = 30000;  // 30 seconds

// ============================================================
// LED COLORS
// ============================================================
uint32_t COLOR_GREEN  = pixel.Color(0,   200, 0);
uint32_t COLOR_ORANGE = pixel.Color(255, 100, 0);
uint32_t COLOR_RED    = pixel.Color(255, 0,   0);
uint32_t COLOR_BLUE   = pixel.Color(0,   0,   200);

// ============================================================
// SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n=============================");
  Serial.println("Safety Helmet IoT - Starting");
  Serial.println("ESP32-S3 Zero | " + String(HELMET_ID));
  Serial.println("=============================");

  // LED
  pixel.begin();
  pixel.setBrightness(60);
  setLED(COLOR_BLUE);

  // DHT22
  dht.begin();
  Serial.println("[OK] DHT22 initialized on GPIO 4");

  // MPU6050
  Wire.begin(SDA_PIN, SCL_PIN);
  mpu.initialize();
  if (mpu.testConnection()) {
    Serial.println("[OK] MPU6050 connected on GPIO 8/9");
  } else {
    Serial.println("[FAIL] MPU6050 not found");
  }

  // GPS
  gpsSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("[OK] GPS Serial on GPIO 17/18");

  // Buzzer
  pinMode(BUZZER_PIN, OUTPUT);
  noTone(BUZZER_PIN);
  Serial.println("[OK] Buzzer on GPIO 12");

  // WiFi
  connectWiFi();

  // Firebase - Anonymous auth
  config.api_key               = API_KEY;
  config.database_url          = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("[OK] Firebase initialized");

  // Wait for Firebase ready
  Serial.print("[..] Authenticating");
  int authWait = 0;
  while (!Firebase.ready() && authWait < 20) {
    delay(500);
    Serial.print(".");
    authWait++;
  }
  Serial.println();

  if (Firebase.ready()) {
    Serial.println("[OK] Firebase ready");
    Firebase.RTDB.setString(&fbdo, "/helmets/" + String(HELMET_ID) + "/status", "online");
    fetchThresholds();
    beep(2);
    setLED(COLOR_GREEN);
  } else {
    Serial.println("[WARN] Firebase not ready");
    beep(1);
  }

  Serial.println("[OK] Monitoring started");
}

// ============================================================
// MAIN LOOP
// ============================================================
void loop() {
  unsigned long now = millis();

  // Feed GPS
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }

  // Read sensors
  readDHT();
  readMPU();
  readGPS();

  // Check alerts
  checkAlerts();

  // Upload every 5 seconds
  if (now - lastUpdate >= UPDATE_INTERVAL) {
    lastUpdate = now;
    uploadData();
  }

  // Refresh thresholds every 30 seconds
  if (now - lastThreshFetch >= THRESH_INTERVAL) {
    lastThreshFetch = now;
    fetchThresholds();
  }
}

// ============================================================
// WIFI
// ============================================================
void connectWiFi() {
  Serial.print("[..] Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[OK] WiFi: " + WiFi.localIP().toString());
    // Sync time via NTP
    configTime(28800, 0, "pool.ntp.org"); // UTC+8 Philippines
    Serial.print("[..] Syncing NTP time");
    int ntpWait = 0;
    while (time(nullptr) < 100000 && ntpWait < 20) {
      delay(500);
      Serial.print(".");
      ntpWait++;
    }
    Serial.println("\n[OK] Time synced: " + String(time(nullptr)));
  } else {
    Serial.println("\n[WARN] WiFi failed - will retry on next upload");
  }
}

// ============================================================
// SENSORS
// ============================================================
void readDHT() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (!isnan(t) && !isnan(h)) {
    temperature = t;
    humidity    = h;
  }
}

void readMPU() {
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  accelX = ax / 16384.0;
  accelY = ay / 16384.0;
  accelZ = az / 16384.0;
  gyroX  = gx / 131.0;
  gyroY  = gy / 131.0;
  gyroZ  = gz / 131.0;
  gForce = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
}

void readGPS() {
  if (gps.location.isValid() && gps.location.age() < 2000) {
    latitude  = gps.location.lat();
    longitude = gps.location.lng();
    gpsValid  = true;
  } else {
    gpsValid = false;
  }
  satellites = gps.satellites.isValid() ? gps.satellites.value() : 0;
}

// ============================================================
// ALERT CHECKING
// ============================================================
void checkAlerts() {
  bool alert = false;
  fallen = false;

  if (gForce > gforceThreshold) {
    fallen = true;
    alert  = true;
    Serial.println("[ALERT] High G-Force: " + String(gForce, 2) + "G");
  }

  if (temperature > tempThreshold) {
    alert = true;
    Serial.println("[ALERT] High Temp: " + String(temperature, 1) + "C");
  }

  if (alert) {
    setLED(COLOR_RED);
    beep(3);
  } else {
    setLED(gpsValid ? COLOR_GREEN : COLOR_ORANGE);
  }
}

// ============================================================
// BUZZER
// ============================================================
void beep(int times) {
  for (int i = 0; i < times; i++) {
    tone(BUZZER_PIN, 4500);
    delay(150);
    noTone(BUZZER_PIN);
    delay(100);
  }
}

// ============================================================
// LED
// ============================================================
void setLED(uint32_t color) {
  pixel.setPixelColor(0, color);
  pixel.show();
}

// ============================================================
// FIREBASE UPLOAD
// ============================================================
void uploadData() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
    return;
  }

  if (!Firebase.ready()) {
    Serial.println("[WARN] Firebase not ready");
    return;
  }

  String path = "/helmets/" + String(HELMET_ID);

  FirebaseJson json;
  json.set("status",      "online");
  json.set("temperature", temperature);
  json.set("humidity",    humidity);
  json.set("gforce",      gForce);
  json.set("accelX",      accelX);
  json.set("accelY",      accelY);
  json.set("accelZ",      accelZ);
  json.set("gyroX",       gyroX);
  json.set("gyroY",       gyroY);
  json.set("gyroZ",       gyroZ);
  json.set("fallen",      fallen);
  json.set("lastSeen",    (int)time(nullptr));

  FirebaseJson locJson;
  locJson.set("latitude",   latitude);
  locJson.set("longitude",  longitude);
  locJson.set("satellites", satellites);
  locJson.set("valid",      gpsValid);
  json.set("location", locJson);

  if (Firebase.RTDB.updateNode(&fbdo, path, &json)) {
    Serial.println("[OK] Upload | T:" + String(temperature, 1) +
                   "C H:" + String(humidity, 1) +
                   "% G:" + String(gForce, 2) +
                   "G GPS:" + String(gpsValid ? "Fix" : "NoFix"));
  } else {
    Serial.println("[FAIL] " + fbdo.errorReason());
  }
}

// ============================================================
// FETCH THRESHOLDS
// ============================================================
void fetchThresholds() {
  if (!Firebase.ready()) return;

  if (Firebase.RTDB.getJSON(&fbdoSettings, "/settings/thresholds")) {
    FirebaseJson    &json = fbdoSettings.jsonObject();
    FirebaseJsonData result;

    json.get(result, "temperature");
    if (result.success) tempThreshold = result.floatValue;

    json.get(result, "gforce");
    if (result.success) gforceThreshold = result.floatValue;

    Serial.println("[OK] Thresholds | T:" + String(tempThreshold) +
                   "C G:" + String(gforceThreshold) + "G");
  }
}
