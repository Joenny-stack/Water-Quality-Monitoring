#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <LiquidCrystal_I2C.h>
#include <WiFiManager.h>  // Add this for captive portal

// Web server setup
ESP8266WebServer server(80);

// Hardware pin definitions
#define LED_PIN LED_BUILTIN
#define BUZZER_PIN D4
#define waterLevelPin D3

// LCD initialization
LiquidCrystal_I2C lcd(0x27, 16, 2);  // Adjust address if needed

// State flags
bool ledState = false;
bool buzzerState = false;

// Global sensor readings
int turbidityValue = 0;
float turbidity = 0.0;
int waterStatus = 0;

// Function to return device status
void handleStatus() {
  String json = "{";
  json += "\"connected\": true,";
  json += "\"led_on\": " + String(ledState ? "true" : "false") + ",";
  json += "\"buzzer_on\": " + String(buzzerState ? "true" : "false") + ",";
  json += "\"turbidity\": " + String(turbidity, 2) + ",";
  json += "\"water_detected\": " + String(waterStatus == HIGH ? "true" : "false");
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
  lcd.print("Turbidity: ");

  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(waterLevelPin, INPUT);

  // Wi-FiManager captive portal
  WiFiManager wm;
  if (!wm.autoConnect("ESP8266_Setup")) {
    Serial.println("Failed to connect & timed out");
    ESP.restart();
    delay(1000);
  }

  Serial.println("WiFi connected: " + WiFi.localIP().toString());
  lcd.setCursor(0, 0);
  lcd.print(WiFi.localIP());

  server.on("/status", handleStatus);
  server.begin();
}

void loop() {
  server.handleClient();

  turbidityValue = 1024 - analogRead(A0);
  turbidity = map(turbidityValue, 0, 1023, 0, 100);
  waterStatus = digitalRead(waterLevelPin);

  lcd.setCursor(11, 1);
  lcd.print("     ");
  lcd.setCursor(11, 1);
  lcd.print(turbidity);
  lcd.print(" %");

  if (waterStatus == HIGH) {
    // Optional: Add some alert logic here
  } else {
    Serial.println("No Water Detected");
  }

  delay(1000);
}
