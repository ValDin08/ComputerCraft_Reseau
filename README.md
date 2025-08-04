# CraftNET — Protocole réseau (legacy) pour CC:Tweaked
CraftNET est un protocole simple basé sur RedNet (modem CC:Tweaked) permettant de faire communiquer turtles, relais et serveurs.
Il s’appuie sur des identifiants numériques de requêtes/réponses et des trames (tables Lua) contenant les données utiles.

> [!NOTE]
> Statut : en évolution. Pour de nouveaux projets ou des besoins avancés, voir le protocole PixelLink (messages typés, payloads structurés, supervision multi-sites).

## 🎯 Objectifs
Connexion turtle/serveur et maintien de session

Autorisation de production pilotée par le serveur

Télémetrie “statut” : position, orientation, cycles de prod, carburant, inventaire synthétique

Intégration de relais (états de coffres, etc.)

## 🔌 Prérequis
CC:Tweaked ≥ 1.94  
Un modem activé : rednet.open("<side>")  
Un ID unique par machine (serveur, turtle, relais)  

## 🧱 Format de base des trames
Deux familles :

Demandes : table Lua avec RequestID = <int> + champs utiles

Réponses : table Lua avec AnswerID = <int> + champs utiles

Champs recommandés (facultatifs mais utiles) :

SourceID : os.getComputerID() de l’émetteur

ServerID : ID du serveur cible (dans les réponses serveur)

ProgramVersion : version du programme émetteur

Timestamps si besoin : os.epoch("utc")

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

## ✅ Bonnes pratiques
Toujours répondre aux demandes (1/2/30), même par un refus (103).

Heartbeat régulier (statut) avec jitter (sleep(3 + math.random())) pour éviter les envois simultanés.

Timeouts côté turtle : sans réponse/autorisation récente → pause, retour base.

Journaliser côté serveur (horodatage, SourceID, Request/AnswerID) pour faciliter le debug.

Versionner vos programmes (ProgramVersion) et vos configs d’ID.

## 🧩 Compatibilité & évolutions
CraftNET reste supporté pour vos installations existantes.

> [!NOTE]
> Pour des besoins plus riches (messages typés, supervision multi-sites, inventaires détaillés), envisagez la migration vers PixelLink.

> [!TIP]
> Une passerelle CraftNET ↔ PixelLink est possible (traduction des trames).
