<p align="center">    
<img width="700" height="700" alt="Relais 3" src=https://github.com/user-attachments/assets/ae20e0fc-c098-4fc4-9223-1f0db1444626>
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/ed9d7c93-42b9-4f00-a5ab-595a9fa1a3b3" /> [Version française](../../Relais/README.md)

# Relays – CC:Tweaked

This folder contains the programs intended for **relay PCs** used to monitor the state of chests (fuel, harvest, etc.) in the PixelLink / CraftNET ecosystem.

---

## Overview

Relays act as “sensors” between servers and turtles. They monitor the filling level of associated chests (fuel, wood, harvests, etc.) and transmit this information to servers via the PixelLink network protocol.  
In the future, they may also act as repeater nodes between a relay/turtle and a local server, or between a local server and the global server. --> Not yet implemented in PixelLink v1.0.2.

---

## Features

- Real-time monitoring of chest fill rate.
- Periodic status transmission to the local server.
- Multi-chest management possible (e.g.: fuel on the right, wood on the left…).
- Full integration with the PixelLink protocol (status, alerts, authorization).

---

## Current version : 2.1

### 📝 Patchnote :
<details>
  
<summary>Display previous versions history</summary>

*1.0 : Basic version of relays program.*

*2.0 : PixelLink integration to relays.*

</details>

**2.1 : Fixed several blocking bugs in the program (`inventory` table constructor with missing commas, mis-prefixed `Chest.SlotQty` variable, `Chest.ChestsItemQty`→`Chest.ChestItemQty` typo, `Chest.ChestSide` never actually set from config).  
The relay program now stays identical across every instance: the announced service name, display name, and chest side are configured only through the arguments passed in `shell.run`/`startup.lua` (`RelayHostname`, `RelayName`, `ChestSide`).  
Added server discovery by name (`PixelLink.resolve`) with periodic retries, and the relay now announces itself under its own name (`PixelLink.host`) so the server can find it.  
Fixed the chest fill-rate calculation, which assumed a uniform 64-item cap per slot: it now uses each item's real capacity (`item.maxCount`) for every occupied slot.**

---
## Usage

1. **Installation**: Place the `Relay.lua` and `PixelLink.lua` files in the relay PC's folder.
2. **Configuration**: `Relay.lua` stays strictly identical across every relay. All instance-specific configuration (announcement name, display name, monitored chest side) is passed as startup arguments.
3. **Startup**: Start the program with the command (in `startup.lua`, adapted per relay):
```
local JOB = "Relay"
local RELAY_HOSTNAME = "bucheron_fuel_relay"  -- name this relay announces itself under
local RELAY_NAME = "Fuel"                     -- display name in logs/console
local CHEST_SIDE = "front"                    -- side of the monitored chest
shell.run(JOB, RELAY_HOSTNAME, RELAY_NAME, CHEST_SIDE)
```

4. Relays will identify themselves to the server and continuously send their status.

---

## Requirements

- CC:Tweaked (Minecraft mod)
- PixelLink (network module, version ≥ 1.0-beta04, for name-based service discovery)
- A modem (wired or wireless) connected to the relay PC
- A local server running version **v5.0-alpha02** or higher (for automatic relay resolution by name)

## Tips

### Multiple Chests

Each chest to monitor gets its own relay instance (one PC per chest), started with its own announcement name and chest side. Since `Relay.lua` is identical everywhere, just adapt the arguments passed to `shell.run`/`startup.lua` (see [Usage](#usage)):

```
-- Fuel relay
shell.run("Relay", "bucheron_fuel_relay", "Fuel", "front")

-- Logs relay (on a different PC)
shell.run("Relay", "bucheron_harvest_relay", "Logs", "front")
```
On the server side, `Server.retryMissingRelays()` resolves each name to an ID independently — no further adaptation is needed.
