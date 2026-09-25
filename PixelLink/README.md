<img width="1108" height="386" alt="image" src="https://github.com/user-attachments/assets/a6ee35af-42a3-48e8-b43b-096884e06a47" />

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/a03063ab-5834-437d-846d-acc130d903ab" /> [English version](../English/PixelLink/README.md)

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

## Version actuelle : 1.0-beta04

### 📝 Patchnote :
<details>
  
<summary>Voir l'historique des versions précédentes</summary>

*1.0-alpha01 : Version de base de PixelLink.*

*1.0-beta01 : Patch correctif.*

*1.0-beta02 : Patch correctif.*

*1.0-beta03 : Correction d'une fuite de variable globale dans `PixelLink.receive` (payload non local).  
`PixelLink.request` attend désormais réellement le délai complet demandé, en ignorant les messages sans rapport avec la requête en cours, au lieu de se satisfaire du premier message reçu de n'importe qui.  
Ajout d'une corrélation requête/réponse (`replyTo`) : une réponse n'est acceptée que si elle répond bien à CETTE requête précise, évitant qu'une réponse tardive à une ancienne requête soit prise pour la bonne.*

</details>

**1.0-beta04 : Ajout de la découverte de service par nom (`PixelLink.host`/`PixelLink.resolve`, basé sur `rednet.host`/`rednet.lookup`) : un turtle/relais/serveur peut désormais s'annoncer sous un nom et être retrouvé par ce nom, sans connaître l'ID de son correspondant à l'avance.  
Isolation du trafic PixelLink des autres usages de Rednet sur le même réseau via un protocole Rednet dédié.**

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
local PixelLink = require("PixelLink")
PixelLink.role = "turtle" -- "relay", "server", ou "supervisor"
PixelLink.serverID = 12   -- ID serveur principal
```
3. Lancez la boucle principale adaptée à votre rôle (voir exemples).

> [!TIP]
> Depuis la v1.0-beta04, plutôt que de coder en dur l'ID du correspondant (`PixelLink.serverID`), vous pouvez annoncer chaque nœud sous un nom (`PixelLink.host("bucheron_server")`) et le retrouver ailleurs sur le réseau par ce nom (`PixelLink.resolve("bucheron_server")`).

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
local PixelLink = require("PixelLink")
PixelLink.role = "turtle"; pixellink.serverID = 12
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
    -- Pause ou sécurité
  end

  sleep(3 + math.random())
end
```

### Côté Serveur
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

## 🔄 Migration depuis CraftNET 
> [!WARNING]
> Obligatoire pour les dernières version de périphériques et serveurs !

Pour migrer de CraftNET à PixelLink, installez le programme PixelLink.lua dans le dossier de votre PC/Turtle, puis installez y la dernière version du programme Turtle/Serveur/Relais disponible.

---

## ✅ Bonnes pratiques PixelLink
Heartbeat régulier avec jitter (sleep(3 + math.random()))

Timeout sécurité côté turtle/relais sans autorisation récente

Logs serveur pour debug et supervision (timestamp, srcID, type message)

Versionnement clair du protocole et programmes

> [!WARNING]
> La retransmission de signal n'est pas encore supportée par la version 1.0-b02. Cette fonction est en cours de développement.

---

## 🙌 Contributions & Questions
Les contributions sont les bienvenues !

Ouvrez une issue pour signaler un problème ou suggérer des améliorations.

Proposez une Pull Request pour contribuer au code ou à la documentation.

---

**PixelLink : Connectez l'avenir, pixel par pixel.**
