<p align="center">    
<img width="700" height="700" alt="Relais 3" src=https://github.com/user-attachments/assets/ae20e0fc-c098-4fc4-9223-1f0db1444626>
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/a03063ab-5834-437d-846d-acc130d903ab" /> [English version](../English/Relays/README.md)

# Relais – CC:Tweaked
Ce dossier contient les programmes destinés aux **PC relais** utilisés pour surveiller l’état des coffres (carburant, récolte, etc.) dans l’écosystème PixelLink / CraftNET.

---

## Présentation
Les relais servent de “capteurs” entre les serveurs et les turtles. Ils surveillent le remplissage des coffres associés (carburant, bois, récoltes…) et transmettent ces informations aux serveurs via le protocole réseau PixelLink.  
Ils pourront ultérieurement servir de borne de retransmission entre un relais/une turtle et un serveur local ou un serveur local et le serveur global. --> Pas encore implémenté dans PixelLink v1.0.2.  

---

## Fonctionnalités
- Surveillance en temps réel du taux de remplissage d'un coffre.
- Transmission périodique de l’état au serveur local.
- Gestion multi-coffre possible (ex : carburant à droite, bois à gauche…).
- Intégration complète avec le protocole PixelLink (statut, alertes, autorisation).

---

## Version actuelle : 2.1

### 📝 Patchnote :
<details>
  
<summary>Voir l'historique des versions précédentes</summary>

*1.0 : Version de base de des relais.*

*2.0 : Intégration de PixelLink aux relais.*

</details>

**2.1 : Correction de plusieurs bugs bloquants du programme (constructeur de la table `inventory` avec des virgules manquantes, variable `Chest.SlotQty` mal préfixée, coquille `Chest.ChestsItemQty`→`Chest.ChestItemQty`, `Chest.ChestSide` jamais renseigné depuis la config).  
Le relais reste désormais identique sur toutes les instances : le nom de service à annoncer, le nom affiché et le côté du coffre se configurent uniquement via les arguments passés en `shell.run`/`startup.lua` (`RelayHostname`, `RelayName`, `ChestSide`).  
Ajout de la découverte du serveur par nom (`PixelLink.resolve`) avec nouvelle tentative périodique, et annonce du relais sous son propre nom (`PixelLink.host`) pour être retrouvé par le serveur.  
Correction du calcul du taux de remplissage du coffre, qui supposait un plafond de 64 uniforme par slot : il utilise désormais la capacité réelle de chaque objet (`item.maxCount`) pour chaque slot occupé.**

---

## Utilisation
1. **Installation** : Place les fichiers `Relais.lua` et `PixelLink.lua` dans le dossier du PC relais.
2. **Configuration** : `Relais.lua` reste strictement identique sur tous les relais. Toute la configuration propre à une instance (nom d'annonce, nom affiché, côté du coffre surveillé) se fait via les arguments passés au lancement.
3. **Lancement** : Démarre le programme avec la commande (dans `startup.lua`, à adapter par relais) :
```
local METIER = "Relais"
local RELAY_HOSTNAME = "bucheron_fuel_relay"  -- nom sous lequel ce relais s'annonce
local RELAY_NAME = "Carburant"                -- nom affiché dans les logs/console
local CHEST_SIDE = "front"                    -- côté du coffre surveillé
shell.run(METIER, RELAY_HOSTNAME, RELAY_NAME, CHEST_SIDE)
```

4. Les relais s’identifient auprès du serveur et transmettent leur état en continu.

---

## Prérequis
- CC:Tweaked (Minecraft mod)
- PixelLink (module réseau, version ≥ 1.0-beta04, pour la découverte de service par nom)
- Un modem (sans fil ou câblé) connecté au PC relais
- Un serveur local sur lequel est installé une version **v5.0-alpha02** ou supérieure (pour la résolution automatique des relais par nom)

---

## Astuces
### Coffres multiples
Chaque coffre à surveiller correspond à une instance de relais distincte (un PC par coffre), lancée avec son propre nom d'annonce et son propre côté de coffre. Le programme `Relais.lua` étant identique partout, il suffit d'adapter les arguments passés en `shell.run`/`startup.lua` (voir [Utilisation](#utilisation)) :

```
-- Relais carburant
shell.run("Relais", "bucheron_fuel_relay", "Carburant", "front")

-- Relais bois (sur un autre PC)
shell.run("Relais", "bucheron_harvest_relay", "Bois", "front")
```
Côté serveur, `Serveur.retryMissingRelays()` résout chaque nom en ID indépendamment, aucune adaptation supplémentaire n'est nécessaire.
