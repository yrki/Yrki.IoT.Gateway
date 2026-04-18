```
     __ __     _   _
    |  |  |___| |_|_|
    |_   _|  _| '_| |     Y R K I  ·  I o T · G a t e w a y
      |_| |_| |_,_|_|
```

# Yrki.IoT.Gateway

WMBus gateway for Wurth Metis-II. Lytter pa WMBus-telegrammer via
seriellport og publiserer til en MQTT-broker. Skrevet i C++17.

```
  +------------------+        +-------------------+        +----------------+
  |  Wurth Metis-II  | serial |                   |  MQTT  |                |
  |  (WMBus radio)   |------->|   wmbus-gateway   |------->|  MQTT Broker   |
  |                  | 9600bd |                   |        |                |
  +------------------+        +-------------------+        +----------------+
                                     |                            |
                                     | gateway/position           | wmbus/raw
                                     | (hvert 5. minutt)          | (per telegram)
                                     v                            v
                              +--------------+            +--------------+
                              |  Posisjon /  |            |  WMBus data  |
                              |  heartbeat   |            |  til backend |
                              +--------------+            +--------------+
```

## MQTT-meldinger

### `wmbus/raw` — WMBus-telegrammer

Publiseres for hvert mottatt telegram:

```json
{
  "payloadHex": "2E449344...",
  "gatewayId":  "gw-001",
  "rssi":       -65,
  "timestamp":  "2026-04-01T12:00:00.0000000+00:00"
}
```

### `gateway/position` — Gateway-heartbeat

Publiseres hvert 5. minutt:

```json
{
  "gatewayId":  "gw-001",
  "timestamp":  "2026-04-01T12:00:00.0000000+00:00",
  "lon":        null,
  "lat":        null,
  "heading":    null,
  "driveBy":    false
}
```

## Prosjektstruktur

```
 Yrki.IoT.Gateway/
 |
 |-- src/                     C++-kildekode
 |   |-- main.cpp             Hovedprogram, heartbeat-trad
 |   |-- mqtt_client.cpp/h    MQTT-klient (libmosquitto)
 |   |-- metis_protocol.cpp/h Metis-II rammeprotokoll
 |   |-- wmbus_parser.cpp/h   WMBus-telegram-parsing
 |   |-- serial_port.cpp/h    Seriellport-kommunikasjon
 |   |-- options.h            Kommandolinje-argumenter
 |   |-- hex.h                Hex-encoding
 |   +-- log.cpp/h            Logging med tidsstempler
 |
 |-- build/                   Byggescript
 |   |-- build-native.sh      Bygg lokalt (macOS / Linux)
 |   |-- build-rpi.sh         Bygg pa Raspberry Pi via SSH
 |   |-- build-rutos.sh       Krysskompiler for Teltonika RUTOS
 |   +-- toolchain-rutos.cmake  CMake-toolchain for RUTOS
 |
 |-- deploy/                  Deploy-script og konfigurasjon
 |   |-- deploy.sh            Deploy til Teltonika RUTOS-enhet
 |   |-- deploy-rpi.sh        Deploy til Raspberry Pi
 |   |-- config.env           Konfigurasjon for RUTOS-deploy
 |   +-- config-rpi.env       Konfigurasjon for RPi-deploy
 |
 |-- developer-tools/         Verktoy for utvikling
 |   |-- run-native.sh        Kjor lokalt bygd binary
 |   +-- start-dashboard.sh   Auto-detect port, koble til dashboard
 |
 +-- CMakeLists.txt           CMake-prosjektfil
```

## Hurtigstart

### Forutsetninger

```
 +---------------------------------------+
 |  macOS / Linux                        |
 |---------------------------------------|
 |  - CMake                              |
 |  - C++17-kompilator (g++ / clang++)   |
 |  - libmosquitto                       |
 +---------------------------------------+

 macOS:   brew install cmake mosquitto
 Debian:  sudo apt install cmake g++ libmosquitto-dev
```

### Bygg og kjor lokalt

```bash
build/build-native.sh
developer-tools/run-native.sh --port /dev/ttyUSB0 --mqtt-host localhost
```

### Deploy til Raspberry Pi

```bash
deploy/deploy-rpi.sh
```

Interaktiv veiviser som:
1. Installerer avhengigheter pa Pi
2. Kopierer kildekode via rsync
3. Bygger pa Pi
4. Installerer systemd-service
5. Starter automatisk

### Deploy til Teltonika RUTOS

```bash
build/build-rutos.sh       # Krever RUTOS SDK
deploy/deploy.sh
```

Interaktiv veiviser som installerer procd-service pa OpenWrt.

## Script-referanse

```
 +=============================+==============================================+
 |  Script                     |  Beskrivelse                                 |
 +=============================+==============================================+
 |                             |                                              |
 |  build/                     |  BYGGESCRIPT                                 |
 |  -------------------------  |  ------------------------------------------  |
 |  build-native.sh            |  Bygger for gjeldende plattform (macOS/Linux)|
 |  build-rpi.sh               |  SSH til RPi, installerer deps, bygger der   |
 |  build-rutos.sh             |  Krysskompilerer for Teltonika ARM (RUTOS)   |
 |                             |                                              |
 +-----------------------------+----------------------------------------------+
 |                             |                                              |
 |  deploy/                    |  DEPLOY-SCRIPT                               |
 |  -------------------------  |  ------------------------------------------  |
 |  deploy.sh                  |  Full deploy til RUTOS-enhet (procd-service) |
 |  deploy-rpi.sh              |  Full deploy til RPi (build + systemd)       |
 |  config.env                 |  Standard-konfig for RUTOS (IP, port, MQTT)  |
 |  config-rpi.env             |  Standard-konfig for RPi (hostname, MQTT)    |
 |                             |                                              |
 +-----------------------------+----------------------------------------------+
 |                             |                                              |
 |  developer-tools/           |  UTVIKLINGSVERKTOY                           |
 |  -------------------------  |  ------------------------------------------  |
 |  run-native.sh              |  Kjorer lokalt bygd binary med argumenter    |
 |  start-dashboard.sh         |  Auto-detect seriellport, kobler til         |
 |                             |  dashboard.yrki.net                          |
 |                             |                                              |
 +=============================+==============================================+
```

## Kommandolinje-argumenter

```
 wmbus-gateway [OPTIONS]

 --port <path>         Seriellport            (standard: /dev/ttyUSB0)
 --baud <rate>         Baudrate               (standard: 9600)
 --gateway-id <id>     Gateway-identifikator  (standard: hostname)
 --mqtt-host <host>    MQTT broker            (standard: localhost)
 --mqtt-port <port>    MQTT port              (standard: 1883)
 --topic <topic>       MQTT topic             (standard: wmbus/raw)
 --activate            Aktiver Metis-II-modul for mottak
 --dump-params         Dump alle Metis-II-parametere og avslutt
 --help                Vis hjelp
```
