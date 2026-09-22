<p align="center">
<img width="733" height="740" alt="serveur fermier" src="https://github.com/user-attachments/assets/3683572c-9c25-475d-8eef-ecf7e2f3f9cb" />
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/a03063ab-5834-437d-846d-acc130d903ab" /> [English version](README_en.md)

# 🌐 Serveur Fermier — CC:Tweaked

Bienvenue dans le serveur **Fermier** pour ComputerCraft !  
Ce serveur gère la supervision, l’autorisation et la gestion des turtles et relais associés à la production de blé/carotte…].

## Version actuelle : 3.0-alpha01
### Génération : Lumen 🔆

### 🚀 Générations

Chaque génération regroupe une évolution majeure commune à toutes les turtles du projet (bûcheron, fermier, mineur...), indépendamment du numéro de version propre à chacune :

| Génération | Nom | Caractéristique |
|---|---|---|
| 1 | **Flint** | Version manuelle de base : rechargement/déchargement à la main, sans réseau ni GPS. |
| 2 | **Vector** | Autonomie complète : guidage GPS, gestion automatique de l'inventaire, rangées multiples. |
| 3 | **Echo** | Arrivée du réseau : communication avec un serveur (protocole CraftNET), arrêt à distance. |
| 4 | **Nexus** | Protocole PixelLink : communications consolidées, détection de rotation intelligente. |
| 5 | **Lumen** | Pilotage tactile complet depuis l'écran du serveur, fin du levier physique. |

### 📝 Patchnote
<details>

<summary>Voir l'historique des versions précédentes</summary>

*1.0 : Version de base du serveur de la turtle fermier, protocole CraftNET.  
Gestion de l'autorisation de fonctionnement de la turtle, si celle ci perd la communication avec le serveur, elle arrête de fonctionner.  
Reception d'une trame basique de statut de la turtle.  
Gestion d'un IHM basique.*

</details>

**3.0-alpha01 : Migration complète de CraftNET vers PixelLink.  
Passage d'un programme unique (`serveurFermier.lua`) à une architecture module + point d'entrée (`Serveur.lua` + `startup.lua`), identique à celle du serveur bûcheron.  
Suppression du levier redstone physique, remplacé par une autorisation manuelle pilotée depuis l'écran (combinée à la sécurité automatique de remplissage du coffre de dépôt).  
Ajout d'une grille de boutons tactiles : Autoriser/Stopper, Acquitter, Reconnexion, Forcer Ravitaillement, Forcer Vidange.  
Nouveau canal de commande fiabilisé avec accusé de réception (jamais de commande perdue en cas de message manqué).  
Le serveur affiche désormais le dernier défaut remonté par la turtle.  
Correction d'un timeout de connexion non fonctionnel : l'état "Turtle connectée" ne redevenait jamais NON après une perte de connexion réelle.  
Le champ `Coffre buches` (resté d'un copier-coller du serveur bûcheron) est renommé `Coffre récolte`, plus juste pour une ferme de blé.**

---

## ⚙️ Fonctionnalités principales

- 🔗 Communication robuste avec une ou plusieurs turtles et relais via **PixelLink** (ou CraftNET)
- 🖥️ Supervision en temps réel via un écran monitor (état, inventaire, alertes…)
- ✅ Gestion de l’autorisation de travail (pause, arrêt, sécurité)
- 📦 Surveillance des niveaux de coffres/relais associés
- 🚨 Alerte automatique en cas de défaut ou de besoin d’intervention

---

## 🚀 Installation du serveur

1. **Placez les programmes** `Serveur.lua`, `startup.lua` et `PixelLink.lua` sur un ordinateur ComputerCraft (PC ou serveur dédié).
2. **Ajoutez un modem** sur l’ordinateur, du côté de votre choix (`back`, `right`, etc).
3. **Connectez un écran monitor** sur un côté de l’ordinateur pour la supervision locale et le pilotage tactile.
4. **Assurez-vous que les turtles/relais soient configurés avec le même protocole PixelLink et la même ID serveur.**

**Démarrage rapide :** Lors du démarrage du PC (Ctrl + R, démarrage serveur ou save), le serveur démarre automatiquement (`startup.lua`) et se met en attente de messages.

## 📡Configuration
Modifier les IDs
Dans le script, configurez :

ServerID : l’ID de votre serveur (par défaut : celui du computer)

TurtleIDs : liste des IDs turtles acceptées (ou à découvrir dynamiquement)

RelaisIDs : liste des relais associés (optionnel)

ModemSide : côté du modem (back, right, etc)

ScreenSide : côté de l’écran (left, bottom, etc)

## 🖥️ Supervision IHM
Le serveur affiche en temps réel sur l’écran :

État des turtles connectées

Autorisation accordée/refusée

Quantité de ressources dans les coffres/relais

Dernières alertes ou défauts

Nombre de cycles de production

> [!IMPORTANT]
> Dépendant de PixelLink version à jour sur toutes les turtles et relais connectés.
> Le module PixelLink est [disponible sur GitHub](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/PixelLink).

> [!IMPORTANT]
> Les Turtles connectées doivent au moins être en version **3.0-alpha01** (génération **Lumen**) pour ce serveur : une turtle antérieure ne parle pas PixelLink et ne pourra pas s'y connecter.

> [!IMPORTANT]
> Un relais doit être intégré au réseau.

> [!NOTE]
> La fiabilité du réseau dépend du placement correct des modems et de la puissance RedNet dans le monde.

> [!TIP]
> Pour une supervision centrale, il est recommandé d’installer un “serveur central” qui collecte tous les états des sites locaux.

## 🔧 Dépannage (FAQ)
Turtle non détectée ?
→ Vérifiez l’ID de la turtle et que le modem est bien actif des deux côtés.

Aucun affichage sur l’écran ?
→ Vérifiez la variable ScreenSide dans la config, testez avec /peripherals dans l’invite de commande.

Le serveur n’autorise pas le travail
→ Vérifiez l’état des coffres, du redstone, et la configuration des relais.

## 🤝 Contributions
Toute contribution, idée ou correction est la bienvenue !
Ouvrez une issue ou une pull request sur ce dépôt.
