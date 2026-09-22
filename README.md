<p align="center">
<img width="300" height="163" alt="ComputerCraft" src="https://github.com/user-attachments/assets/22fbc8d9-fc20-4273-b375-d2101ff1841f" />
</p>

<img width="16" height="16" alt="image" src="https://github.com/user-attachments/assets/a03063ab-5834-437d-846d-acc130d903ab" /> [English version](English/README.md)

# Réseau des machines – CraftNET/PixelLink (ComputerCraft)
Bibliothèque et scripts réseau universels pour turtles, relais et serveurs sous ComputerCraft.  
Objectif : unifier la communication, la supervision et le pilotage (autorisation de production, alertes, inventaires, positions, etc.) dans une architecture modulable et extensible.

## ✨ Fonctionnalités
CraftNET : protocole historique (héritage), simple, basé sur des RequestID/AnswerID.

PixelLink : protocole moderne, structuré, extensible (messages typés, payloads, rôles, supervision multi-sites).

## ⚙️ Etat composants réseau

![GitHub](https://img.shields.io/badge/PixelLink-Beta_v1.0--b03-yellow)
![GitHub](https://img.shields.io/badge/CraftNET-Legacy_v1.0-lightblue)
![GitHub](https://img.shields.io/badge/Serveur_Bucheron-Alpha_v5.0--a01-orange)
![GitHub](https://img.shields.io/badge/Serveur_Fermier-Stable_v1.0-green)
![GitHub](https://img.shields.io/badge/Relais-Alpha_v2.0--a01-orange)


> [!TIP]
> Nouveaux déploiements → PixelLink.  
> Systèmes existants → rester en CraftNET ou migrer progressivement via les versions fournies.



## 🧱 Architecture & rôles

Exemple d'architecture réseau typique. Les liaisons sont assurées par PixelLink, en SingleCast ou en BroadCast : 

<p align="center">
<img width="1773" height="320" alt="Architecture réseau fr" src="https://github.com/user-attachments/assets/6b861a51-0078-4019-af2e-721f026b1bb7" />
</p>

Turtle : envoie son état, attend l’autorisation, exécute les ordres.

Relais : publie l’état des coffres (remplissage…), relaie des capteurs.

Serveur : agrège les états, décide de l’autorisation, affiche IHM/monitor.

Superviseur (optionnel) : centralise tous les serveurs de production.
