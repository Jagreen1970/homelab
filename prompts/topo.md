# Topologie meines Heimnetzwerks

## Physische Topologie

### Keller

Im Keller stehen im Moment ein zentraler Switch und ein Patchfeld, worüber die Netzewerkkabel in alle relevanten Räume verteilt werden.

- **Wohnzimmer** -> 1x
- **Arbeitszimmer Unten** -> 1x
- **Arbeitszimmer Oben** -> 2x
- **Serverraum Oben** -> 2x

### Wohnzimmer

An der Netzwerkdose im Wohnzimmer befindet sich ein Switch, an den ein Smart-TV und ein Firestick angeschlossen sind.

### Arbeitszimmer Unten

Das Netzerkkabel endet hier in einer Dose. Ein kleiner Switch verbindet mehrere Notebooks.

### Serverraum Oben

Die Netzwerkkabel enden in einer Dose. Außerdem kommt hier die DSL Leitung an, die mit dem Router (Fritzbox 7490) verbunden ist.
Vom Router geht ein Kabel zu meinem Rack, wo es als WAN-Anschluss meiner Firewall (OPNsense) dient. Der LAN-Ausgang der Firewall ist mit einem Switch verbunden, der wiederum mehrere Geräte versorgt.
Ein Kabel geht vom Switch zur Dose und dient somit als 'Versorgung' für den Switch im Keller, der damit hinter der Firewall steht und den Rest des Hauses versorgt.

## Arbeitszimmer Oben

Die beiden Netzwerkkabel enden in einer Doppeldose. Insgesamt werde mehrere Geräte über drei Switches verbunden:
Switch 1 verteilt auf Switch 2 und Switch 3. Switch 2 versorgt mehrere Rechner (Desktop-PC, Laptop), während Switch 3 für 2 NAS genutzt wird.

## Software-Topologie

### Firewall (OPNsense)

#### DNSMasq

### NAS Zaphod (Synology)

Zaphod war bisher soetwas wie die Schaltzentrale meines Heimnetzwerks. Hier laufen verschiedene Container, die unterschiedliche Dienste bereitstellen.

#### Portainer

In Portainer laufen zwei Stacks: Nextcloud und Gitlab.

##### Nextcloud Stack

Der Nextcloud Stack besteht aus mehreren Containern, die zusammen die Nextcloud-Instanz bereitstellen. Dazu gehören unter anderem:

- MariaDB als Datenbank
- Redis als Cache
- PHPMyAdmin zur Verwaltung der Datenbank
- Nextcloud selbst
- NginxProxymanager als Reverse Proxy für den Zugriff von außen

Das docker-compose.yml für den Nextcloud Stack ist unter folgendem Link zu finden: [Nextcloud Stack](../manifests/portainer/nextcloud.yml)

##### Gitlab Stack

Der Gitlab Stack besteht aus einem einzigen Container, der die Gitlab-Instanz bereitstellt.

Das docker-compose.yml für den Gitlab Stack ist unter folgendem Link zu finden: [Gitlab Stack](../manifests/portainer/gitlab.yml)

##### NginxProxymanager

Obwohl NginxProxymanager im Nextcloud Stack läuft, wird er auch für andere Dienste genutzt, um den Zugriff von außen zu ermöglichen.

### NAS Wowbagger (QNAP)

Wowbagger wird als Standalone Fileserver genutzt und ist ansonsten nicht in die übrige Infrastruktur eingebunden.
Trozdem sollte Wowbagger natürlich eine IP-Adresse vom DHCP-Server der OPNsense bekommen.
