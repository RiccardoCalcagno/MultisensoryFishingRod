#include "WiFi.h"
#include "AsyncUDP.h"

const char * ssid = "NomeSSID";
const char * password = "nonmelaricordo";
IPAddress myIP(192,168,1,170);
IPAddress myGATEWAY(192,168,1,1);
IPAddress mySUBNET(255,255,255,0);
IPAddress serverIP(192,168,1,47);
int serverPORT = 6969;

AsyncUDP udp;

void setup()
{
    Serial.begin(115200);
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

    if(udp.connect(serverIP, serverPORT)) {

        Serial.println("UDP connected");

        udp.onPacket([](AsyncUDPPacket packet) {
            Serial.print("UDP Packet Type: ");
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
            packet.printf("Got %u bytes of data", packet.length());
        });
    }
}

void loop()
{
    delay(1000);
    udp.print("Hello Server!\n");
}
