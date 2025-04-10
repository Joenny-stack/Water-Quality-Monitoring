#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <LiquidCrystal_I2C.h>

// Wi-Fi credentials
const char* ssid = "GZU EXAMS";
const char* password = "exam5@2020";

// Web server setup
ESP8266WebServer server(80);

// Hardware pin definitions
#define LED_PIN LED_BUILTIN
#define BUZZER_PIN D4
#define waterLevelPin D3  // Make sure you define the water level sensor pin

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
  json += "\"turbidity\": " + String(turbidity, 2) + ",";  // 2 decimal places
  json += "\"water_detected\": " + String(waterStatus == HIGH ? "true" : "false");
  json += "}";

  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(9600);
  lcd.init();
  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("Welcome!");
  lcd.setCursor(0, 1);
  lcd.print("Turbidity: ");

  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(waterLevelPin, INPUT);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected. IP address: ");
  Serial.println(WiFi.localIP());

  server.on("/status", handleStatus);
  server.begin();
}

void loop() {
  server.handleClient();

  turbidityValue = 1024 - analogRead(A0);  // Read from turbidity sensor
  turbidity = map(turbidityValue, 0, 1023, 0, 100);  // Convert to percentage
  waterStatus = digitalRead(waterLevelPin);         // Read water level

  lcd.setCursor(11, 1);
  lcd.print("     ");  // Clear previous value
  lcd.setCursor(11, 1);
  lcd.print(turbidity);
  lcd.print(" %");

  if (waterStatus == HIGH) {
    Serial.println("Water Detected");
  } else {
    Serial.println("No Water Detected");
  }

  delay(1000);
}

