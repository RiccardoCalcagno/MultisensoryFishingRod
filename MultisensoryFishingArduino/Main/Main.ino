#include "WiFi.h"
#include "AsyncUDP.h"

// CONFIG NETWORK AND WIFI
const char * ssid = "Vodafone-Righele";
const char * password = "manu2808";
IPAddress myIP(192,168,1,90);
IPAddress myGATEWAY(192,168,1,1);
IPAddress mySUBNET(255,255,255,0);
IPAddress serverIP(192,168,1,35);
int serverPORT = 6969;

// PINs
struct PinConfig {
  int EncP1=12;
  int EncP2=13;
  int LED=4;
} PIN;

// UDP vars
AsyncUDP udp;
struct WriteConfig {
  const char * rawEnc="raw/enc:%d\n";
  const char * rawAccX="raw/acx:%.2f\n";
  const char * rawAccY="raw/acy:%.2f\n";
  const char * rawAccZ="raw/acz:%.2f\n";
  const char * eventStrong="evn/strong\n";
} WRITE;

void setup()
{
  //Declare PINS
  pinMode(PIN.EncP1, INPUT_PULLUP);
  pinMode(PIN.EncP2, INPUT_PULLUP);
  pinMode(PIN.LED, OUTPUT);
  Serial.begin(115200);

  //Setup WIFI
  analogWrite(PIN.LED, 1);
  WiFi.mode(WIFI_STA);
  if (!WiFi.config(myIP, myGATEWAY, mySUBNET)) {
    Serial.println("STA Failed to configure");
  }
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.print("\nWiFi Success: ");
  Serial.println(WiFi.localIP());

  //Setup handlers
  if(udp.connect(serverIP, serverPORT)) {
      analogWrite(PIN.LED, 0);
      udp.onPacket([](AsyncUDPPacket packet) {
          /*Serial.print("UDP Packet Type: ");
          Serial.print(packet.isBroadcast()?"Broadcast":packet.isMulticast()?"Multicast":"Unicast");
          Serial.print(", From: ");
          Serial.print(packet.remoteIP());
          Serial.print(":");
          Serial.print(packet.remotePort());
          Serial.print(", To: ");
          Serial.print(packet.localIP());
          Serial.print(":");
          Serial.print(packet.localPort());
          Serial.print(", Length: ");
          Serial.print(packet.length());
          Serial.print(", Data: ");
          Serial.write(packet.data(), packet.length());
          Serial.println();
          //reply to the client
          packet.printf("Got %u bytes of data", packet.length());*/
      });
  }
}

int8_t countEnc=0, dirEnc=0;
uint32_t timeEncCalc=0, timeEncRead=0;
uint8_t stateEnc=0, prevStateEnc=0;
float velEnc;

void loop()
{
    /*** SENSOR READINGS/WRITINGS ***/

    // Rotary encoder reads every 0.5 ms
    if(micros()-timeEncRead>500)
    {
      stateEnc = digitalRead(PIN.EncP1);
      if(!stateEnc && prevStateEnc)
      {
        dirEnc = digitalRead(PIN.EncP2) ? -1 : 1; 
        countEnc++;
      }
      prevStateEnc = stateEnc;
      timeEncRead=micros();
    }

    /*** COMPUTATION AND SENDINGS ***/

    // Compute and send velocity of the rod every 200 ms
    if(millis()-timeEncCalc>200)
    {
      udp.printf(WRITE.rawEnc, countEnc*dirEnc); //ticks per 200ms
      countEnc=0;
      timeEncCalc=millis();
    }

}


















