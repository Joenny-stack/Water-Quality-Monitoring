#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <LiquidCrystal_I2C.h>
#include <WiFiManager.h>

// Pin definitions using GPIO numbers
#define LED_PIN        LED_BUILTIN
#define BUZZER_PIN     2     // D4
#define SOLENOID_PIN   0     // D3 - relay control for solenoid
#define MUX_S0         14    // D5
#define MUX_S1         12    // D6
#define MUX_S2         13    // D7

// Analog sensor channels on multiplexer
#define PH_CHANNEL            0
#define TURBIDITY_CHANNEL     1
#define WATER_LEVEL_CHANNEL   2

// LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Web server
ESP8266WebServer server(80);

// Sensor values
float turbidity = 0.0;
float phValue = 0.0;
int waterLevelRaw = 0;

// States
bool buzzerState = false;
bool ledState = false;
bool solenoidState = false;

// Multiplexer read
int readMux(byte channel) {
  digitalWrite(MUX_S0, bitRead(channel, 0));
  digitalWrite(MUX_S1, bitRead(channel, 1));
  digitalWrite(MUX_S2, bitRead(channel, 2));
  delay(5);
  return analogRead(A0);
}

// JSON endpoint
void handleStatus() {
  String json = "{";
  json += "\"connected\": true,";
  json += "\"led_on\": " + String(ledState ? "true" : "false") + ",";
  json += "\"buzzer_on\": " + String(buzzerState ? "true" : "false") + ",";
  json += "\"solenoid_closed\": " + String(solenoidState ? "true" : "false") + ",";
  json += "\"ph\": " + String(phValue, 2) + ",";
  json += "\"turbidity\": " + String(turbidity, 2) + ",";
  json += "\"water_level_raw\": " + String(waterLevelRaw);
  json += "}";
  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(9600);
  lcd.init();
  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("Booting...");
  lcd.setCursor(0, 1);
  lcd.print("Connecting...");

  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(SOLENOID_PIN, OUTPUT);
  pinMode(MUX_S0, OUTPUT);
  pinMode(MUX_S1, OUTPUT);
  pinMode(MUX_S2, OUTPUT);

  digitalWrite(SOLENOID_PIN, LOW); // Start with solenoid OPEN
  solenoidState = false;

  // WiFiManager portal
  WiFiManager wm;
  if (!wm.autoConnect("ESP8266_Setup")) {
    Serial.println("Failed to connect & timed out");
    ESP.restart();
    delay(1000);
  }

  Serial.println("WiFi connected: " + WiFi.localIP().toString());
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(WiFi.localIP());

  server.on("/status", handleStatus);
  server.begin();
}

void loop() {
  server.handleClient();

  // --- Read sensors ---
  int turbidityRaw = readMux(TURBIDITY_CHANNEL);
  float voltage = turbidityRaw * (3.3 / 1023.0);
  turbidity = -1120.4 * sq(voltage) + 5742.3 * voltage - 4352.9;
  if (turbidity < 0) turbidity = 0;

  int phRaw = readMux(PH_CHANNEL);
  phValue = (float)phRaw * (14.0 / 1023.0);

  waterLevelRaw = readMux(WATER_LEVEL_CHANNEL);

  // --- Serial debug output ---
  Serial.println("=== Sensor Readings ===");
  Serial.println("Turbidity RAW: " + String(turbidityRaw));
  Serial.println("Turbidity (NTU): " + String(turbidity, 2));
  Serial.println("PH RAW: " + String(phRaw));
  Serial.println("PH: " + String(phValue, 2));
  Serial.println("Water Level RAW: " + String(waterLevelRaw));
  Serial.println("========================");

  // --- LCD Display ---
  lcd.setCursor(0, 1);
  lcd.print("PH:");
  lcd.print(phValue, 1);
  lcd.print(" T:");
  lcd.print(turbidity, 1);

  // --- Alerts and Solenoid control ---
  if (waterLevelRaw > 200) {
    digitalWrite(BUZZER_PIN, HIGH);
    digitalWrite(SOLENOID_PIN, LOW); // Relay ON (valve CLOSED)
    buzzerState = true;
    solenoidState = true;
    Serial.println("Water Level HIGH - Buzzer ON, Valve CLOSED");
  } else {
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(SOLENOID_PIN, HIGH); // Relay OFF (valve OPEN)
    buzzerState = false;
    solenoidState = false;
    Serial.println("Water Level LOW - Buzzer OFF, Valve OPEN");
  }


  delay(1000);
}
