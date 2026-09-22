<p align="center">
<img width="733" height="740" alt="farm server" src="https://github.com/user-attachments/assets/3683572c-9c25-475d-8eef-ecf7e2f3f9cb" />
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/ed9d7c93-42b9-4f00-a5ab-595a9fa1a3b3" /> [Version française](README.md)

# 🌐 Farmer Server — CC:Tweaked

Welcome to the **Farmer** server for ComputerCraft!  
This server manages the supervision, authorization, and control of turtles and relays involved in wheat/carrot production, etc.

## Current Version: 3.0-alpha01
### Generation: Lumen 🔆

### 🚀 Generations

Each generation groups a major evolution shared by every turtle in the project (lumberjack, farmer, miner...), independently of each one's own version number:

| Generation | Name | Defining trait |
|---|---|---|
| 1 | **Flint** | Basic manual version: hand-loaded/unloaded, no network, no GPS. |
| 2 | **Vector** | Full autonomy: GPS guidance, automatic inventory management, multiple rows. |
| 3 | **Echo** | Network arrives: communication with a server (CraftNET protocol), remote stop. |
| 4 | **Nexus** | PixelLink protocol: consolidated communications, smart rotation detection. |
| 5 | **Lumen** | Full touchscreen control from the server screen, no more physical lever. |

### 📝 Patchnote
<details>

<summary>See previous version history</summary>

*1.0: Initial version of the farmer turtle server, CraftNET protocol.  
Manages work authorization for the turtle: if communication is lost, the turtle stops.  
Receives basic status frames from the turtle.  
Basic HMI management.*

</details>

**3.0-alpha01: Full migration from CraftNET to PixelLink.  
Moved from a single program (`serveurFermier.lua`) to a module + entry-point architecture (`Server.lua` + `startup.lua`), identical to the lumberjack server's.  
Removed the physical redstone lever, replaced by manual authorization controlled from the screen (combined with the automatic safety check on the drop-off chest filling level).  
Added a touchscreen button grid: Authorize/Stop, Acknowledge, Reconnect, Force Refuel, Force Empty.  
New reliable command channel with acknowledgement (a command is never lost if a message drops).  
The server now displays the last fault reported by the turtle.  
Fixed a non-functional connection timeout: the "Turtle connected" status never went back to NO after an actual disconnection.  
The `Wood chest` field (a leftover from copy-pasting the lumberjack server) is renamed `Harvest chest`, more accurate for a wheat farm.**

---

## ⚙️ Main Features

- 🔗 Robust communication with one or several turtles and relays via **PixelLink** (or CraftNET)  
- 🖥️ Real-time monitoring via a screen (status, inventory, alerts…)  
- ✅ Work authorization management (pause, stop, safety)  
- 📦 Monitoring of chests/relays inventory levels  
- 🚨 Automatic alerting in case of fault or intervention needed  

---

## 🚀 Server Installation

1. **Place the `Server.lua`, `startup.lua`, and `PixelLink.lua` programs** on a ComputerCraft computer (PC or server).  
2. **Add a modem** to the computer, on your chosen side (`back`, `right`, etc).  
3. **Attach a monitor** to one side of the computer for local supervision and touchscreen control.  
4. **Ensure all turtles/relays are configured with the same PixelLink protocol and server ID.**  

**Quick Start:** On PC startup (`Ctrl + R`, server boot, or on world load), the server starts automatically (`startup.lua`) and waits for messages.


## 📡Configuration
Edit the IDs
In the script, configure:

ServerID: your server’s ID (default: computer’s own ID)

TurtleIDs: list of accepted turtle IDs (or dynamic discovery)

RelaisIDs: list of relay IDs (optional)

ModemSide: modem side (back, right, etc)

ScreenSide: screen side (left, bottom, etc)

## 🖥️ HMI Supervision
The server displays in real time on the screen:

Status of connected turtles

Granted/denied work authorization

Chest/relay resource quantities

Last alerts or faults

Number of production cycles

> [!IMPORTANT]
> Requires an up-to-date PixelLink version on all connected turtles and relays.  
> The PixelLink module is [available on GitHub](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/PixelLink).

> [!IMPORTANT]
> Connected turtles must be at least version **3.0-alpha01** (generation **Lumen**) for this server: an older turtle doesn't speak PixelLink and won't be able to connect.

> [!IMPORTANT]
> At least one relay must be connected to the network.

> [!NOTE]
> Network reliability depends on proper modem placement and RedNet power in the world.

> [!TIP]
> For central monitoring, consider installing a “central server” to collect all local site statuses.

## 🔧 Troubleshooting (FAQ)
Turtle not detected?  
→ Check the turtle’s ID and that the modem is active on both sides.

No display on the screen?  
→ Check the ScreenSide variable in the config, try /peripherals in the command prompt.

Server does not authorize work?  
→ Check chest status, redstone signal, and relay configuration.


## 🤝 Contributions
All contributions, ideas, or corrections are welcome!  
Open an issue or a pull request on this repository.
