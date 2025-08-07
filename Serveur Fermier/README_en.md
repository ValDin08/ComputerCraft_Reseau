<p align="center">
<img width="733" height="740" alt="farm server" src="https://github.com/user-attachments/assets/3683572c-9c25-475d-8eef-ecf7e2f3f9cb" />
</p>

# 🌐 Farmer Server — CC:Tweaked

Welcome to the **Farmer** server for ComputerCraft!  
This server manages the supervision, authorization, and control of turtles and relays involved in wheat/carrot production, etc.

## Current Version: 1.0

### 📝 Patchnote
*1.0: Initial version of the lumberjack turtle server.  
Manages work authorization for the turtle: if communication is lost, the turtle stops.  
Receives basic status frames from the turtle.  
Basic HMI management.*

---

## ⚙️ Main Features

- 🔗 Robust communication with one or several turtles and relays via **PixelLink** (or CraftNET)  
- 🖥️ Real-time monitoring via a screen (status, inventory, alerts…)  
- ✅ Work authorization management (pause, stop, safety)  
- 📦 Monitoring of chests/relays inventory levels  
- 🚨 Automatic alerting in case of fault or intervention needed  

---

## 🚀 Server Installation

1. **Place the `serveurFermier.lua` program** on a ComputerCraft computer (PC or server).  
2. **Add a modem** to the computer, on your chosen side (`back`, `right`, etc).  
3. **Attach a monitor** to one side of the computer for local supervision.  
4. **Ensure all turtles/relays use the same CraftNET protocol and server ID.**  

**Quick Start:**

```
-- startup.lua
shell.run("serveurFermier")
```


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
> Requires an up-to-date CraftNET version on all turtles and relays.

> [!IMPORTANT]
> Connected turtles must be at least version **2.0**.

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