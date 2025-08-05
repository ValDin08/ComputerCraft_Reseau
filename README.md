<p align="center">
<img width="937" height="956" alt="serveur bucheron" src="https://github.com/user-attachments/assets/5dc106d3-fa58-4c1d-983b-3d4ff9ed897d" />
</p>

# 🌐 Serveur Bucheron — CC:Tweaked

Bienvenue dans le serveur **Bucheron** pour ComputerCraft !  
Ce serveur gère la supervision, l’autorisation et la gestion des turtles et relais associés à la production de [bois/blé/minerais…].

## Version actuelle : 3.0

### 📝 Patchnote
*1.0 : Version de base du serveur de la turtle bucheron.  
Gestion de l'autorisation de fonctionnement de la turtle, si celle ci perd la communication avec le serveur, elle arrête de fonctionner.  
Reception d'une trame basique de statut de la turtle.*

*2.0 : Intégration d'un PC relais coffre conditionnant l'autorisation de travail de la turtle.*

**3.0 : Ajout d'un écran IHM pour supervision de la turtle.  
Gestion de l'autorisation de production via serveur relais coffre ET signal redstone TOR devant IHM.**

---

## ⚙️ Fonctionnalités principales

- 🔗 Communication robuste avec une ou plusieurs turtles et relais via **PixelLink** (ou CraftNET)
- 🖥️ Supervision en temps réel via un écran monitor (état, inventaire, alertes…)
- ✅ Gestion de l’autorisation de travail (pause, arrêt, sécurité)
- 📦 Surveillance des niveaux de coffres/relais associés
- 🚨 Alerte automatique en cas de défaut ou de besoin d’intervention

---

## 🚀 Installation du serveur

1. **Placez le programme** `serveurBucheron.lua` sur un ordinateur ComputerCraft (PC ou serveur dédié).
2. **Ajoutez un modem** sur l’ordinateur, du côté de votre choix (`back`, `right`, etc).
3. **Connectez un écran monitor** sur un côté de l’ordinateur pour la supervision locale.
4. (Optionnel) **Assurez-vous que les turtles/relais sont configurés avec le même protocole PixelLink et la même ID serveur.**

**Démarrage rapide :**
```lua
-- startup.lua
shell.run("serveurBucheron")
```

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
> Dépendant à CraftNET version à jour sur toutes les turtles et relais connectés.

> [!IMPORTANT]
> Les Turtles connectées doivent au moins être en version **3.0**.

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
