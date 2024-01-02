#include "WiFi.h"
#include "AsyncUDP.h"
#include "ADS1X15.h"

// CONFIG NETWORK AND WIFI
const char * ssid = "Vodafone-Righele";
const char * password = "manu2808";
IPAddress myIP(192,168,1,90);
IPAddress myGATEWAY(192,168,1,1);
IPAddress mySUBNET(255,255,255,0);
int myPORT = 6969;
IPAddress serverIP(192,168,1,35);
int serverPORT = 6969;

// PINs
struct PinConfig {
  int EncP1=12;
  int EncP2=13;
  int LED=33;
  int Actuators=2;
  int SDA=14;
  int SCL=15;
} PIN;

// UDP vars
AsyncUDP udp_tx, udp_rx;
struct WriteConfig {
  const char * rawEnc="raw/enc:%d\n";
  const char * rawAccX="raw/acx:%d\n";
  const char * rawAccY="raw/acy:%d\n";
  const char * rawAccZ="raw/acz:%d\n";
} WRITE;

// I2C vars
ADS1115 ADS(0x48, &Wire1);

// Utils
uint8_t starts_with(const char * str, const char * starts_str, const uint8_t starts_len)
{
  uint8_t i=0, check=1;
  while(i<starts_len && check){
    check = starts_str[i] == str[i];
    i++;
  }
  return check;
}
uint32_t string_from(const char * str, char * out, const char separator, const int MAX_SIZE)
{
  int i=0, j=0;
  while(i<MAX_SIZE && str[i]!=separator)
    i++;
  i++;
  while(i<MAX_SIZE && str[i]!='\0' && str[i]!='\n'){
    out[j]=str[i];
    i++; j++;
  }
  out[j]='\0';
  return j;
}
uint32_t string_to_uint32(const char * str, uint8_t len)
{
  uint32_t num=0;
  uint8_t pos=0;
  while(len>0){
    num += (int)(str[len-1]-'0') * (int)(pow(10, pos));
    len--;
    pos++;
  }
  return num;
}

// Handlers
IRAM_ATTR void UDP_rx_cb(AsyncUDPPacket packet)
{
  if(packet.length()<50)
  {
    char * data = (char *)packet.data();
    if(starts_with(data, "set/act:", 8))
    {
      char value[50];
      uint32_t len = string_from(data, value, ':', 50);
      uint32_t value_int = string_to_uint32(value, len);
      analogWrite(PIN.Actuators, value_int);
    }
  }
}

void setup()
{
  //Declare PINS
  pinMode(PIN.EncP1, INPUT_PULLUP);
  pinMode(PIN.EncP2, INPUT_PULLUP);
  pinMode(PIN.LED, OUTPUT);
  pinMode(PIN.Actuators, OUTPUT);
  Serial.begin(115200);

  //Setup ADS for accelerometer
  Wire1.begin(PIN.SDA, PIN.SCL, 100000); // freq 100 KHz
  ADS.begin();
  ADS.setGain(2);      //  +-2.048 volt
  ADS.setDataRate(7);  //  0 = slow   4 = medium   7 = fast
  ADS.setMode(1);      //  continuous mode
  while (!ADS.isConnected()) {
    digitalWrite(PIN.LED, LOW);
    delay(50);
    digitalWrite(PIN.LED, HIGH);
    delay(500);
  }

  //Setup WIFI
  digitalWrite(PIN.LED, LOW);
  WiFi.mode(WIFI_STA);
  WiFi.config(myIP, myGATEWAY, mySUBNET);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    digitalWrite(PIN.LED, LOW);
    delay(250);
    digitalWrite(PIN.LED, HIGH);
    delay(250);
  }

  //Setup handlers
  digitalWrite(PIN.LED, LOW);
  if(udp_tx.connect(serverIP, serverPORT) && udp_rx.listen(myPORT)) {
      digitalWrite(PIN.LED, HIGH);
      udp_rx.onPacket(UDP_rx_cb);
  }
}

int8_t countEnc=0, dirEnc=0, ADSreading=3, readyAcc=0;
uint16_t valAccX, valAccY, valAccZ;
uint32_t timeEncSend=0, timeEncRead=0;
uint8_t stateEnc=0, prevStateEnc=0;

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

    // Accelerometer ASAP (every ~10ms, ADS timings)
    if(!readyAcc)
    {
      switch(ADSreading)
      {
        case 0:
          if(ADS.isReady())
          {
            valAccX = ADS.getValue();
            ADSreading++;
            ADS.requestADC(ADSreading);
          }
          break;
        case 1:
          if(ADS.isReady())
          {
            valAccY = ADS.getValue();
            ADSreading++;
            ADS.requestADC(ADSreading);
          }
          break;
        case 2:
          if(ADS.isReady())
          {
            valAccZ = ADS.getValue();
            ADSreading++;
            readyAcc=1;
          }
          break;
        default:
          ADSreading=0;
          ADS.requestADC(ADSreading);
      }      
    }

    /*** COMPUTATION AND SENDINGS ***/

    // Compute and send velocity of the rod every 200 ms
    if(millis()-timeEncSend>200)
    {
      udp_tx.printf(WRITE.rawEnc, countEnc*dirEnc); //ticks per 200ms
      countEnc=0;
      timeEncSend=millis();
    }

    // Send acceleration on x y z when it's ready
    if(readyAcc)
    {
      udp_tx.printf(WRITE.rawAccX, valAccX);
      udp_tx.printf(WRITE.rawAccY, valAccY);
      udp_tx.printf(WRITE.rawAccZ, valAccZ);
      readyAcc=0;
    }

}


















