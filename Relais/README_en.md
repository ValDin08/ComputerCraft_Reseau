<p align="center">    
<img width="640" height="640" alt="turtle bucheron" src=https://github.com/user-attachments/assets/73cd67e0-4629-429a-ab7e-46a531eb5b43>
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/ed9d7c93-42b9-4f00-a5ab-595a9fa1a3b3" /> [Version française](README.md)

# Relays – CC:Tweaked

This folder contains the programs intended for **relay PCs** used to monitor the state of chests (fuel, harvest, etc.) in the PixelLink / CraftNET ecosystem.

## Overview

Relays act as “sensors” between servers and turtles. They monitor the filling level of associated chests (fuel, wood, harvests, etc.) and transmit this information to servers via the PixelLink network protocol.  
In the future, they may also act as repeater nodes between a relay/turtle and a local server, or between a local server and the global server. --> Not yet implemented in PixelLink v1.0.2.

## Features

- Real-time monitoring of chest fill rate.
- Periodic status transmission to the local server.
- Multi-chest management possible (e.g.: fuel on the right, wood on the left…).
- Full integration with the PixelLink protocol (status, alerts, authorization).

## Usage

1. **Installation**: Place the `Relay.lua` file in the relay PC's folder.
2. **Configuration**: Edit the slot/side parameters according to your chest setup.
3. **Startup**: Start the program with the command:
```
*local METIER = "Relais"
shell.run(METIER)*
```
> [!TIP]
> **Alternative**: Copy the code from *Relay.lua* into your *startup.lua* file.

4. Relays will identify themselves to the server and continuously send their status.

## Requirements

- CC:Tweaked (Minecraft mod)
- PixelLink (network module, version ≥ 1.0.2)
- A modem (wired or wireless) connected to the relay PC
- A local server running version **v4.0** or higher

## Tips

### Multiple Chests

To handle multiple chests, create another *RelayName* variable (e.g., *RelayNameBis*) and another chest table (e.g., *Chest2*).  
When sending your first set of messages, use *RelayName*, then on the next send, use *RelayNameBis*:



```
-- Globales
  local RelayVersion	=	"1.0"	    -- Version actuelle du programme
  local RelayName     =	"Carburant"	-- Nom du relais principal
  local RelayNameBis  =	"Bois"	-- Nom du relais alternatif
[...]
-- Envoi de la demande de connexion au serveur par le relais principal
  ConnectToServer(RelayName)  

-- Actualisation du comptage du coffre 1
  ChestFillingPercentage(Chest1)

-- Envoi du statut du coffre 1
  StatusToServer(Chest1)

-- Envoi de la demande de connexion au serveur par le relais alternatif
  ConnectToServer(RelayNameBis)  

-- Actualisation du comptage du coffre 2
  ChestFillingPercentage(Chest2)

-- Envoi du statut du coffre 2
  StatusToServer(Chest2)
```
Just adapt the ConnectToServer function so that it sends the relay name in the payload, and on the server side, make sure reception checks the relay name rather than just its id.