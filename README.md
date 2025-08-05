<img width="1108" height="386" alt="image" src="https://github.com/user-attachments/assets/a6ee35af-42a3-48e8-b43b-096884e06a47" />

## 🌐 PixelLink
PixelLink est un protocole réseau avancé pour ComputerCraft (CC:Tweaked), conçu pour connecter efficacement turtles, relais, serveurs et superviseurs dans vos environnements Minecraft.

Avec PixelLink, reliez vos machines, simplifiez votre univers.

---

## ✨ Fonctionnalités clés
✅ Structure claire : messages typés, lisibles, et évolutifs.

🔄 Communication robuste : états réguliers, autorisations fiables.

🚀 Supervision centralisée : multi-turtles, multi-sites, gestion facile.

📊 États détaillés : position, inventaire, cycles de production, carburant, défauts.

---

## Version actuelle : 1.0

### 📝 Patchnote :
**1.0 : Version de base de PixelLink.**

---

## 🔌 Prérequis

ComputerCraft (CC:Tweaked) ≥ 1.94.

Modem présent.

Satellite GPS présent et actif sur la carte.

---

## ⚙️ Installation rapide
1. Placez PixelLink.lua sur chaque turtle/relais/serveur.

2. Chargez PixelLink dans vos scripts :
```
local pixellink = require("PixelLink")
pixellink.role = "turtle" -- "relay", "server", ou "supervisor"
pixellink.serverID = 12   -- ID serveur principal
```
3. Lancez la boucle principale adaptée à votre rôle (voir exemples).

---

##📝 Exemple de message PixelLink
PixelLink utilise des messages typés pour une lisibilité maximale :
```
{
  msgType = "status" | "auth" | "alert" | "command" | "request",
  srcType = "turtle" | "relay" | "server" | "supervisor",
  srcID   = os.getComputerID(),
  dstID   = ID cible (nil = broadcast),
  ts      = os.epoch("utc"),
  payload = { ... } -- contenu structuré
}
```
### Exemple d’état Turtle :
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

## 🚀 Exemples rapides
### Côté Turtle
```
local pixellink = require("PixelLink")
pixellink.role = "turtle"; pixellink.serverID = 12
rednet.open("right")

while true do
  pixellink.sendStatus({
    pos = {gps.locate()},
    orientation = 1,
    inventory = {fuel=32, saplings=20},
    fuel = turtle.getFuelLevel(),
    cycles = myCycles,
    running = true
  })

  local auth = pixellink.waitForAuth(3)
  if not auth or not auth.authorized then
    -- Pause ou sécurité
  end

  sleep(3 + math.random())
end
```

### Côté Serveur
```
local pixellink = require("PixelLink")
pixellink.role = "server"
rednet.open("back")

local turtles = {}

while true do
  local id, msg = rednet.receive(10)
  if msg and msg.msgType == "status" then
    turtles[msg.srcID] = msg.payload
    pixellink.sendAuth(msg.srcID, {authorized=true})
  end
end
```

---

## 🔄 Migration depuis CraftNET (facultatif)
Une passerelle CraftNET ↔ PixelLink est disponible dans bridge_craftnet.lua.

---

## ✅ Bonnes pratiques PixelLink
Heartbeat régulier avec jitter (sleep(3 + math.random()))

Timeout sécurité côté turtle/relais sans autorisation récente

Logs serveur pour debug et supervision (timestamp, srcID, type message)

Versionnement clair du protocole et programmes

---

## 🙌 Contributions & Questions
Les contributions sont les bienvenues !

Ouvrez une issue pour signaler un problème ou suggérer des améliorations.

Proposez une Pull Request pour contribuer au code ou à la documentation.

---

**PixelLink : Connectez l'avenir, pixel par pixel.**
