<p align="center">    
<img width="700" height="700" alt="Relais 3" src=https://github.com/user-attachments/assets/ae20e0fc-c098-4fc4-9223-1f0db1444626>
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/a03063ab-5834-437d-846d-acc130d903ab" /> [English version](README_en.md)

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

## Version actuelle : 2.0

### 📝 Patchnote :
<details>
  
<summary>Voir l'historique des versions précédentes</summary>

*1.0 : Version de base de des relais.*

</details>

**2.0 : Intégration de PixelLink aux relais.**

---

## Utilisation
1. **Installation** : Place le fichier `Relais.lua` dans le dossier du PC relais.
2. **Configuration** : Modifie les paramètres de slot/côté selon ta configuration de coffres.
3. **Lancement** : Démarre le programme avec la commande :
```
*local METIER = "Relais"
shell.run(METIER)*
```
> [!TIP]
> **Autre solution** : copiez le code contenu dans *Relais.lua* dans votre *startup.lua*.

4. Les relais s’identifient auprès du serveur et transmettent leur état en continu.

---

## Prérequis
- CC:Tweaked (Minecraft mod)
- PixelLink (module réseau, version ≥ 1.0.2)
- Un modem (sans fil ou câblé) connecté au PC relais
- Un serveur local sur lequel est installé une version **v4.0** ou supérieure

---

## Astuces
### Coffres multiples
Pour gérer plusieurs coffres, créez une autre variable *RelayName*, par exemple *RelayNameBis* et une autre table de coffre, par exemple *Chest2*.  
Lorsque vous envoyez votre premier ensemble de message, envoyez les messages sous *RelayName*, puis à l'envoi suivant, envoyez les messages sous *RelayNameBis* :

```
-- Globales
  local RelayVersion	=	"1.0"	    -- Version actuelle du programme
  local RelayName     =	"Carburant"	-- Nom du relais principal
  local RelayNameBis  =	"Bois"	-- Nom du relais alternatif
[...]
-- Envoi de la demande de connexion au serveur par le relais principal
  ConnectToServer(RelayName)  

-- Actualisation du comptage du coffre 1
  ChestFillingPercentage(Chest1)

-- Envoi du statut du coffre 1
  StatusToServer(Chest1)

-- Envoi de la demande de connexion au serveur par le relais alternatif
  ConnectToServer(RelayNameBis)  

-- Actualisation du comptage du coffre 2
  ChestFillingPercentage(Chest2)

-- Envoi du statut du coffre 2
  StatusToServer(Chest2)
```
Il suffira d'adapter la fonction ConnectToServer pour qu'elle envoie le nom du relais en payload, et côté serveur, que la réception lise le nom du relais et plus son id.
