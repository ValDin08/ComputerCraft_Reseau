<p align="center">
<img width="300" height="163" alt="hq720" src="https://github.com/user-attachments/assets/808230f7-743a-485b-88c3-7102a9066de2" />
</p>

# Réseau des machines – CraftNET/PixelLink (ComputerCraft)
Bibliothèque et scripts réseau universels pour turtles, relais et serveurs sous ComputerCraft.  
Objectif : unifier la communication, la supervision et le pilotage (autorisation de production, alertes, inventaires, positions, etc.) dans une architecture modulable et extensible.

## ✨ Fonctionnalités
CraftNET : protocole historique (héritage), simple, basé sur des RequestID/AnswerID.

PixelLink : protocole moderne, structuré, extensible (messages typés, payloads, rôles, supervision multi-sites).

## ⚙️ Etat composants réseau

![GitHub](https://img.shields.io/badge/PixelLink-Beta_v1.0--b02-yellow)
![GitHub](https://img.shields.io/badge/CraftNET-Legacy_v1.0-lightblue)
![GitHub](https://img.shields.io/badge/Serveur_Bucheron-Alpha_v4.0--a03-orange)
![GitHub](https://img.shields.io/badge/Serveur_Fermier-Stable_v1.0-green)
![GitHub](https://img.shields.io/badge/Relais-Alpha_v2.0--a01-orange)


> [!TIP]
> Nouveaux déploiements → PixelLink.  
> Systèmes existants → rester en CraftNET ou migrer progressivement via les versions fournies.



## 🧱 Architecture & rôles
Turtle : envoie son état, attend l’autorisation, exécute les ordres.

Relais : publie l’état des coffres (remplissage…), relaie des capteurs.

Serveur : agrège les états, décide de l’autorisation, affiche IHM/monitor.

Superviseur (optionnel) : centralise tous les serveurs de production.
