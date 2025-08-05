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
