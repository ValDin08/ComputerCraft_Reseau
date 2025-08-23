<p align="center">
<img width="300" height="163" alt="hq720" src="https://github.com/user-attachments/assets/808230f7-743a-485b-88c3-7102a9066de2" />
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/ed9d7c93-42b9-4f00-a5ab-595a9fa1a3b3" /> [Version française](../README.md)

# Machine Network – CraftNET/PixelLink (ComputerCraft)
Universal network library and scripts for turtles, relays, and servers using ComputerCraft.  
Goal: unify communication, supervision, and control (production authorization, alerts, inventories, positions, etc.) in a modular and extensible architecture.

## ✨ Features
**CraftNET**: Legacy protocol, simple, based on RequestID/AnswerID.

**PixelLink**: Modern, structured, and extensible protocol (typed messages, payloads, roles, multi-site supervision).

## ⚙️ Network Components Status

![GitHub](https://img.shields.io/badge/PixelLink-Beta_v1.0--b02-yellow)
![GitHub](https://img.shields.io/badge/CraftNET-Legacy_v1.0-lightblue)
![GitHub](https://img.shields.io/badge/Timber_server-Alpha_v4.0--a03-orange)
![GitHub](https://img.shields.io/badge/Farmer_server-Stable_v1.0-green)
![GitHub](https://img.shields.io/badge/Relay-Alpha_v2.0--a01-orange)


> [!TIP]
> New deployments → use PixelLink.  
> Existing systems → stay on CraftNET or migrate progressively with the provided versions.


## 🧱 Architecture & Roles

Example of a typical network architecture. Connections are handled by PixelLink, in SingleCast or BroadCast:

<p align="center">
<img width="1773" height="320" alt="Architecture réseau EN" src="https://github.com/user-attachments/assets/fa0f2de5-75ee-4843-a4f7-218c4fcc031a" />
</p>

**Turtle**: sends its state, waits for authorization, executes orders.

**Relay**: publishes chest status (filling level, etc.), relays sensor data.

**Server**: aggregates states, decides on authorization, displays the HMI/monitor.

**Supervisor (optional)**: centralizes all production servers.
