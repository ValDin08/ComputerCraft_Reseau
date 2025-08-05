<p align="center">
<img width="300" height="163" alt="hq720" src="https://github.com/user-attachments/assets/808230f7-743a-485b-88c3-7102a9066de2" />
</p>

# Réseau des machines – CraftNET/PixelLink (ComputerCraft)
Bibliothèque et scripts réseau universels pour turtles, relais et serveurs sous ComputerCraft.
Objectif : unifier la communication, la supervision et le pilotage (autorisation de production, alertes, inventaires, positions, etc.) dans une architecture modulable et extensible.

## ✨ Fonctionnalités
CraftNET : protocole historique (héritage), simple, basé sur des RequestID/AnswerID.

PixelLink : protocole moderne, structuré, extensible (messages typés, payloads, rôles, supervision multi-sites).

> [!TIP]
> Recommandation :  
> Nouveaux déploiements → PixelLink.  
> Systèmes existants → rester en CraftNET ou migrer progressivement via la passerelle fournie.



## 🧱 Architecture & rôles
Turtle : envoie son état, attend l’autorisation, exécute les ordres.

Relais : publie l’état des coffres (remplissage…), relaie des capteurs.

Serveur : agrège les états, décide de l’autorisation, affiche IHM/monitor.

Superviseur (optionnel) : centralise tous les serveurs de production.

---

<p align="center">
<img width="1583" height="1600" alt="wmremove-transformed" src="https://github.com/user-attachments/assets/a657e464-24ba-45ee-98cc-e95a186fb621" />
</p>

# CraftNET — Protocole réseau (legacy) pour CC:Tweaked
CraftNET est un protocole simple basé sur RedNet (modem CC:Tweaked) permettant de faire communiquer turtles, relais et serveurs.
Il s’appuie sur des identifiants numériques de requêtes/réponses et des trames (tables Lua) contenant les données utiles.

> [!NOTE]
> Statut : supporté mais non développé. Pour de nouveaux projets ou des besoins avancés, voir le protocole PixelLink (messages typés, payloads structurés, supervision multi-sites).

## 🎯 Objectifs
Connexion turtle/serveur et maintien de session

Autorisation de production pilotée par le serveur

Télémetrie “statut” : position, orientation, cycles de prod, carburant, inventaire synthétique

Intégration de relais (états de coffres, etc.)

---

## 🔌 Prérequis
CC:Tweaked ≥ 1.94  

Un modem activé : rednet.open("<side>")  

Un ID unique par machine (serveur, turtle, relais)  

---

## 🧱 Format de base des trames
Deux familles :

Demandes : table Lua avec RequestID = <int> + champs utiles

Réponses : table Lua avec AnswerID = <int> + champs utiles

Champs recommandés (facultatifs mais utiles) :

SourceID : os.getComputerID() de l’émetteur

ServerID : ID du serveur cible (dans les réponses serveur)

ProgramVersion : version du programme émetteur

Timestamps si besoin : os.epoch("utc")

---

## 🧭 Tableau des IDs (référence)
### Demandes (1–100)  
| ID | Émetteur |	Signification |
|:---:|:---:|:---:|
| 1	| Turtle/Relais | Demande de connexion au serveur |
| 2	| Turtle |	Demande d’autorisation de travail |  
| 3	| Relais |	Signal de présence / prêt (heartbeat “je suis là”) |  
| 10 | Serveur |	Demande d’état d’une turtle |  
| 30 | Serveur |	Demande d’état d’un relais (coffres, etc.) |  
| 11–29, 31–99 | N/A | Réservés pour extensions locales |   
| 100 | Réservé | Erreurs génériques / fin de plage |   

### Réponses (101–200)  
| ID | Émetteur |	Signification |
|:---:|:---:|:---:| 
| 101 | Serveur | Connexion acceptée |   
| 102 | Serveur | Autorisation accordée |   
| 103 | Serveur | Autorisation refusée / révoquée (recommandé) |  
| 110 | Turtle | Trame d’information (statut) envoyée au serveur |   
| 130 | Relais | Trame d’information (états de coffres) envoyée au serveur | 
| 111–129, 131–199 | N/A | Réservés pour extensions locales |   
| 200 | Réservé | Erreurs génériques / fin de plage |   

> [!NOTE]
> Compat héritage : certains anciens scripts utilisaient 202 pour “interdiction”. Préférez désormais 103.

---

## 📦 Contenus de trames (champs attendus)
### 110 — Statut turtle → serveur
```
{  
  AnswerID = 110,  
  ProgramVersion = "x.y",  
  CurrentTurtlePosition = { x, y, z },   -- table 3 valeurs  
  TurtleOrientation = 1..4,              -- 1=N, 2=S, 3=E, 4=O  
  FuelLevel = <int>,  
  -- Champs métier selon la turtle :  
  TreeHarvestedCurrentRun = <int>,       -- bûcheron  
  HayHarvestedCurrentRun  = <int>,       -- moissonneuse  
  -- etc.  
}
```

### 130 — Statut relais → serveur
```
{
  AnswerID = 130,  
  CurrentLeftChestFilling  = <0..100>,   -- % remplissage coffre gauche  
  CurrentRightChestFilling = <0..100>,   -- % remplissage coffre droit  
  -- Extensions possibles : types de coffres, alertes locales, etc.  
}
```

### 101 / 102 / 103 — Réponses serveur  
-- 101 : connexion OK  
```
{ AnswerID = 101, ServerID = <id> }
```

-- 102 : autorisation accordée  
```
{ AnswerID = 102, reason = "..." }
```

-- 103 : autorisation refusée / révoquée  
```
{ AnswerID = 103, reason = "coffre plein" }
```

---

## 🔁 Flots typiques
**Turtle (client)**  
Envoi {RequestID=1} → reçoit {AnswerID=101}

En boucle :  
a) Demande {RequestID=2} (autorisation) → reçoit {AnswerID=102/103}  
b) Envoi périodique du statut {AnswerID=110, ...}  
c) Adapte son comportement selon l’autorisation  
  
---

**Relais (client)**  
Envoi {RequestID=1} → reçoit {AnswerID=101}  

Périodiquement ou sur demande {RequestID=30} : envoi {AnswerID=130, niveaux de coffres}  
  
---

**Serveur**  
Écoute toutes les trames (rednet.receive), met à jour ses états internes  

Répond aux demandes (1/2/30)  

Décide l’autorisation (102/103) et l’affiche (IHM/monitor)  

---

## 🧪 Exemples (extraits)
**Turtle — connexion + heartbeat**  
```
rednet.open("right")  
local SERVER_ID = 11  

-- Connexion
rednet.send(SERVER_ID, { RequestID = 1 })  
local id, msg = rednet.receive(5)  
assert(id == SERVER_ID and msg and msg.AnswerID == 101, "Connexion serveur échouée")  

while true do  
  -- Autorisation  
  rednet.send(SERVER_ID, { RequestID = 2 })  
  local _, auth = rednet.receive(5)  
  local allowed = auth and auth.AnswerID == 102  

  -- Envoi statut  
  local pos = { gps.locate() }  -- {x,y,z}  
  rednet.send(SERVER_ID, {  
    AnswerID = 110,  
    ProgramVersion = "1.0",  
    CurrentTurtlePosition = { pos[1], pos[2], pos[3] },  
    TurtleOrientation = 1,  
    FuelLevel = turtle.getFuelLevel(),  
    TreeHarvestedCurrentRun = 42  
  })  

  if not allowed then  
    -- Sécurité : pause / retour / attente  
  end  

  sleep(3 + math.random())  -- Jitter  
end   
```

---

**Serveur — squelette minimal**  
```
rednet.open("back")  
local TURTLE_ID = 16  
local RELAY_ID  = 17  

while true do  
  local id, msg = rednet.receive(10)  

  if id == TURTLE_ID and type(msg) == "table" then  
    if msg.RequestID == 1 then  
      rednet.send(TURTLE_ID, { AnswerID = 101 })  
    elseif msg.RequestID == 2 then  
      local authorize = true  -- votre logique  
      rednet.send(TURTLE_ID, { AnswerID = authorize and 102 or 103 })  
    elseif msg.AnswerID == 110 then  
      -- MAJ état turtle (pos, fuel, cycles...)  
    end  

  elseif id == RELAY_ID and type(msg) == "table" then  
    if msg.RequestID == 1 then   
      rednet.send(RELAY_ID, { AnswerID = 101 })  
    elseif msg.RequestID == 30 then  
      -- Si vous “pull”, renvoyer 130 ici  
      rednet.send(RELAY_ID, {  
        AnswerID = 130,  
        CurrentLeftChestFilling  = 47,  
        CurrentRightChestFilling = 83  
      })  
    elseif msg.AnswerID == 130 then  
      -- Si le relais “push”, MAJ états coffres  
    end  
  end  
end
```  

---

## ✅ Bonnes pratiques
Toujours répondre aux demandes (1/2/30), même par un refus (103).

Heartbeat régulier (statut) avec jitter (sleep(3 + math.random())) pour éviter les envois simultanés.

Timeouts côté turtle : sans réponse/autorisation récente → pause, retour base.

Journaliser côté serveur (horodatage, SourceID, Request/AnswerID) pour faciliter le debug.

Versionner vos programmes (ProgramVersion) et vos configs d’ID.

---

## 🧩 Compatibilité & évolutions
CraftNET reste supporté pour vos installations existantes.

> [!NOTE]
> Pour des besoins plus riches (messages typés, supervision multi-sites, inventaires détaillés), envisagez la migration vers PixelLink.

> [!TIP]
> Une passerelle CraftNET ↔ PixelLink est possible (traduction des trames).

---

## 🙌 Contributions & Questions
Les contributions sont les bienvenues !

Ouvrez une issue pour signaler un problème ou suggérer des améliorations.

Proposez une Pull Request pour contribuer au code ou à la documentation.

---

<p align="center">
<img width="1108" height="386" alt="image" src="https://github.com/user-attachments/assets/a6ee35af-42a3-48e8-b43b-096884e06a47" />
</p>

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

