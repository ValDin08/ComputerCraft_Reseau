<img width="1108" height="386" alt="image" src="https://github.com/user-attachments/assets/a6ee35af-42a3-48e8-b43b-096884e06a47" />

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/ed9d7c93-42b9-4f00-a5ab-595a9fa1a3b3" /> [Version française](../../PixelLink/README.md)

## 🌐 PixelLink
PixelLink is an advanced network protocol for ComputerCraft (CC:Tweaked), designed to efficiently connect turtles, relays, servers, and supervisors in your Minecraft environments.

With PixelLink, link your machines and simplify your world.

---

## ✨ Key Features
✅ Clear structure: typed, readable, and extensible messages.

🔄 Robust communication: regular status updates, reliable authorization.

🚀 Centralized supervision: multi-turtle, multi-site, easy management.

📊 Detailed status: position, inventory, production cycles, fuel, errors.

---

## Current Version: 1.0-beta03

### 📝 Patchnote:
<details>
<summary>See previous version history</summary>

*1.0-alpha01: Initial version of PixelLink.*

*1.0-beta01: Bugfix patch.*

*1.0-beta02: Bugfix patch.*

</details>

**1.0-beta03: Fixed a global variable leak in `PixelLink.receive` (payload was not local).  
`PixelLink.request` now actually waits out the full requested timeout, ignoring messages unrelated to the current request, instead of settling for the first message received from anyone.  
Added request/reply correlation (`replyTo`): a reply is only accepted if it actually answers THIS specific request, preventing a late reply to an old request from being mistaken for the right one.**

---

## 🔌 Requirements

- ComputerCraft (CC:Tweaked) ≥ 1.94.
- A modem present.
- A GPS satellite present and active on the map.

---

## ⚙️ Quick Installation
1. Place `PixelLink.lua` on each turtle/relay/server.
2. Load PixelLink in your scripts:
    ```lua
    local PixelLink = require("PixelLink")
    PixelLink.role = "turtle" -- "relay", "server", or "supervisor"
    PixelLink.serverID = 12   -- Main server ID
    ```
3. Start the main loop adapted to your role (see examples).

---

## 📝 PixelLink Message Example
PixelLink uses typed messages for maximum readability:
```lua
{
  msgType = "status" | "auth" | "alert" | "command" | "request",
  srcType = "turtle" | "relay" | "server" | "supervisor",
  srcID   = os.getComputerID(),
  dstID   = Target ID (nil = broadcast),
  ts      = os.epoch("utc"),
  payload = { ... } -- structured content
}

```
### Turtle status example:
```
{
  msgType = "status",
  srcType = "turtle",
  srcID   = 16,
  dstID   = 12,
  ts      = 1710000000,
  payload = {
    pos        = {x=100, y=64, z=200},
    orientation= 1,
    inventory  = { fuel=32, saplings=20, logs=64 },
    fuel       = 1500,
    cycles     = 42,
    running    = true,
    errors     = {}
  }
}
```
---

## 🚀 Quick Examples
### Turtle Side
```
local PixelLink = require("PixelLink")
PixelLink.role = "turtle"; PixelLink.serverID = 12
rednet.open("right")

while true do
  PixelLink.sendStatus({
    pos = {gps.locate()},
    orientation = 1,
    inventory = {fuel=32, saplings=20},
    fuel = turtle.getFuelLevel(),
    cycles = myCycles,
    running = true
  })

  local auth = PixelLink.waitForAuth(3)
  if not auth or not auth.authorized then
    -- Pause or safety stop
  end

  sleep(3 + math.random())
end
```

### Server Side
```
local PixelLink = require("PixelLink")
PixelLink.role = "server"
rednet.open("back")

local turtles = {}

while true do
  local id, msg = rednet.receive(10)
  if msg and msg.msgType == "status" then
    turtles[msg.srcID] = msg.payload
    PixelLink.sendAuth(msg.srcID, {authorized=true})
  end
end
```

---

## 🔄 Migration from CraftNET
> [!WARNING]
> Mandatory for the latest version of peripherals and servers!

To migrate from CraftNET to PixelLink, install the PixelLink.lua program in your PC/Turtle folder, then install the latest available Turtle/Server/Relay program.

---

## ✅ PixelLink Best Practices
Regular heartbeat with jitter (sleep(3 + math.random()))

Safety timeout on turtle/relay without recent authorization

Server logs for debug and supervision (timestamp, srcID, message type)

Clear versioning of the protocol and programs

> [!WARNING]
> Signal retransmission is not yet supported by version 1.0-b02. This feature is under development.

---

## 🙌 Contributions & Questions
Contributions are welcome!

Open an issue to report a problem or suggest improvements.

Propose a Pull Request to contribute code or documentation.

---

**PixelLink : Connecting the future, pixel by pixel.**
