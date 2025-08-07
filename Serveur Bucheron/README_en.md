<p align="center">
<img width="937" height="956" alt="lumberjack server" src="https://github.com/user-attachments/assets/5dc106d3-fa58-4c1d-983b-3d4ff9ed897d" />
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/ed9d7c93-42b9-4f00-a5ab-595a9fa1a3b3" /> [Version française](README.md)

# 🌐 Lumberjack Server — CC:Tweaked

Welcome to the **Lumberjack** server for ComputerCraft!  
This server handles supervision, authorization, and management of turtles and relays involved in wood production.

## Current Version: 4.0-alpha03

### 📝 Patchnote
<details>
  
<summary>View previous version history</summary>
  
*1.0: Initial version of the lumberjack turtle server.  
Manages work authorization for the turtle: if it loses communication with the server, it stops working.  
Receives basic status frames from the turtle.*

*2.0: Integration of a chest relay PC conditioning the turtle's work authorization.*

*3.0: Addition of an HMI screen for turtle supervision.  
Work authorization is now managed via the chest relay server **AND** a redstone input in front of the HMI.*

*v4.0-alpha02: Integration of PixelLink.  
Program updated accordingly.*

</details>

**v4.0-alpha03: Test phase corrections**

---

## ⚙️ Main Features

- 🔗 Robust communication with one or several turtles and relays via **PixelLink** (or CraftNET)
- 🖥️ Real-time supervision via a monitor screen (status, inventory, alerts, etc.)
- ✅ Work authorization management (pause, stop, safety)
- 📦 Monitoring of associated chest/relay levels
- 🚨 Automatic alerting in case of fault or intervention needed

---

## 🚀 Server Installation

1. **Place the programs** `Serveur.lua`, `startup.lua`, and `PixelLink.lua` on a ComputerCraft computer (PC or dedicated server).
2. **Add a modem** to the computer, on your chosen side (`back`, `right`, etc).
3. **Connect a monitor** to a side of the computer for local supervision.
4. **Ensure that turtles/relays are configured with the same PixelLink protocol and server ID.**

**Quick Start:** On PC startup (`Ctrl + R`, server boot, or on world load), the server starts automatically and waits for messages.

## 📡 Configuration
Edit the IDs  
In the script, configure:

ServerID: your server's ID (default: computer's own ID)

TurtleIDs: list of accepted turtle IDs

RelayIDs: list of associated relays

ModemSide: modem side (`back`, `right`, etc)

ScreenSide: screen side (`left`, `bottom`, etc)

## 🖥️ HMI Supervision
The server displays in real time on the monitor:

Status of connected turtles

Authorization granted/refused

Resource quantities in chests/relays

Latest alerts or faults

Number of production cycles

> [!IMPORTANT]
> Depends on up-to-date PixelLink version on all connected turtles and relays.
> The PixelLink module is [available on GitHub](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/PixelLink)

> [!IMPORTANT]
> Connected turtles must be at least **version 4.0**.

> [!IMPORTANT]
> At least one relay must be integrated into the network.

> [!NOTE]
> Network reliability depends on proper modem placement and RedNet signal strength in the world.

> [!TIP]
> For central supervision, it is recommended to install a “central server” that collects all local site statuses.

## 🔧 Troubleshooting (FAQ)
Turtle not detected?  
→ Check the turtle’s ID and ensure the modem is active on both sides.

No display on the screen?  
→ Check the ScreenSide variable in the config, try `/peripherals` in the command prompt.

The server does not authorize work?  
→ Check chest status, redstone signal, and relay configuration.

## 🤝 Contributions
All contributions, ideas, or corrections are welcome!  
Open an issue or a pull request on this repository.
