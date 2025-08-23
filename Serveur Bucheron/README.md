<p align="center">
<img width="937" height="956" alt="serveur bucheron" src="https://github.com/user-attachments/assets/5dc106d3-fa58-4c1d-983b-3d4ff9ed897d" />
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/a03063ab-5834-437d-846d-acc130d903ab" /> [English version](English/Lumberjack_Server/README.md)

# 🌐 Serveur Bucheron — CC:Tweaked

Bienvenue dans le serveur **Bucheron** pour ComputerCraft !  
Ce serveur gère la supervision, l’autorisation et la gestion des turtles et relais associés à la production de bois.

## Version actuelle : 4.0-beta01

### 📝 Patchnote
<details>
  
<summary>Voir l'historique des versions précédentes</summary>
  
*1.0 : Version de base du serveur de la turtle bucheron.  
Gestion de l'autorisation de fonctionnement de la turtle, si celle ci perd la communication avec le serveur, elle arrête de fonctionner.  
Reception d'une trame basique de statut de la turtle.*

*2.0 : Intégration d'un PC relais coffre conditionnant l'autorisation de travail de la turtle.*

*3.0 : Ajout d'un écran IHM pour supervision de la turtle.  
Gestion de l'autorisation de production via serveur relais coffre ET signal redstone TOR devant IHM.*

*v4.0-alpha02 : Intégration de PixelLink.  
Modification du programme en conséquence.*

*v4.0-alpha03 : Corrections phase de test.*

*v4.0-alpha04 : Corrections phase de test.*

</details>

*v4.0-beta01 : Passage en Beta.*

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
3. **Connectez un écran monitor** sur un côté de l’ordinateur pour la supervision locale.
4. **Assurez-vous que les turtles/relais sont configurés avec le même protocole PixelLink et la même ID serveur.**

**Démarrage rapide :** Lors du démarrage du PC (Ctrl + R, démarrage serveur ou save), le serveur démarre automatiquement et se met en attente de messages.

## 📡Configuration
Modifier les IDs
Dans le script, configurez :

ServerID : l’ID de votre serveur (par défaut : celui du computer)

TurtleIDs : liste des IDs turtles acceptées

RelayIDs : liste des relais associés

ModemSide : côté du modem (back, right, etc)

ScreenSide : côté de l’écran (left, bottom, etc)

## 🖥️ Supervision IHM
Le serveur affiche en temps réel sur l’écran :

État des turtles connectées

Autorisation accordée/refusée

Quantité de ressources dans les coffres/relais

Dernières alertes ou défauts

Nombre de cycles de production

Exemple de supervision, adaptable en modifiant la fonction **Serveur.displayHMI()** :

<img width="3840" height="2019" alt="2025-08-07_18 53 04" src="https://github.com/user-attachments/assets/22cad96b-d9b8-4b6a-b213-383f355b6271" />


> [!IMPORTANT]
> Dépendant de PixelLink version à jour sur toutes les turtles et relais connectés.
> Le module PixelLink est [disponible sur GitHub](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/PixelLink)

> [!IMPORTANT]
> Les Turtles connectées doivent au moins être en version **4.0**.

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
→ Vérifiez l’état des coffres, du signal redstone, et la configuration des relais.

## 🤝 Contributions
Toute contribution, idée ou correction est la bienvenue !
Ouvrez une issue ou une pull request sur ce dépôt.
