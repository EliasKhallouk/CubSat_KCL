# 🛰️ NanoOrbit - Phase 5 Application

Application web pour gérer et consulter les données des satellites CubeSat.

## 📋 Étapes réalisées

### ✅ ÉTAPE 1 : Setup du projet (COMPLÈTE)
- [x] Node.js + Express initialisé
- [x] MySQL2 pour la connexion à la base
- [x] Express-session pour la gestion des sessions
- [x] Structure de projet organisée

### ✅ ÉTAPE 2 : Authentification (COMPLÈTE)
- [x] Page de login avec 4 profils
- [x] Gestion des sessions utilisateur
- [x] Middleware de vérification d'authentification
- [x] Détection du profil utilisateur

### ✅ ÉTAPE 3 : Front-office (COMPLÈTE)
- [x] FO-01 : Dashboard des satellites opérationnels
- [x] FO-02 : Bilan des communications par satellite
- [x] FO-03 : Tableau de bord des missions
- [x] FO-04 : Alertes instruments

### ✅ ÉTAPE 4 : Back-office (COMPLÈTE)
- [x] BO-01 : Modifier le statut d'un satellite
- [x] BO-02 : Planifier une fenêtre de communication
- [x] BO-03 : Assigner un satellite à une mission
- [x] BO-04 : Désorbiter un satellite (admin uniquement)
- [x] Contrôle d'accès par profil

## 🚀 Démarrage

### Installation
```bash
cd /home/elias/A4/BDD/CubSat_KCL/nanoOrbit-app
npm install
```

### Lancement
```bash
npm start
```

Puis accédez à: **http://localhost:3000**

## 👤 Comptes de test

| Utilisateur | Mot de passe | Rôle | Accès |
|---|---|---|---|
| `analyste_data` | `Analyste123!` | Analyste | Front-office seulement |
| `operateur_sat` | `Operateur123!` | Opérateur | Front-office + Back-office partiel |
| `resp_mission` | `Mission123!` | Responsable | Front-office + Back-office partiel |
| `admin_nano` | `Admin123!` | Admin | Accès complet |

## 📊 Fonctionnalités

### Front-office (Consultation)
- **Satellites opérationnels** : Liste avec filtre visuel par format
- **Communications** : Résumé des activités par satellite
- **Missions** : État des missions actives
- **Alertes** : Instruments en anomalie

### Back-office (Administration)
- **Modifier statut satellite** : Opérationnel / Veille / Désorbité
- **Planifier communication** : Créer fenêtres avec validation
- **Assigner satellites** : Ajouter satellites aux missions
- **Désorbiter** : Action réservée admin

## 🗂️ Structure du projet

```
nanoOrbit-app/
├── .env                 # Configuration (identifiants)
├── .gitignore
├── package.json
├── server.js            # Serveur principal Express
├── db.js                # Connexion MySQL
├── routes/
│   ├── auth.js         # Login / logout
│   ├── front.js        # Routes front-office (GET)
│   └── back.js         # Routes back-office (POST)
└── README.md
```

## 🔌 Connexion à la base

- **Host:** localhost
- **User:** operateur_sat (peut être modifié)
- **Password:** Operateur123!
- **Database:** nanoOrbit_db

Modifiez `.env` pour utiliser d'autres identifiants.

## 🛡️ Sécurité

- Sessions: 24h TTL
- Authentification obligatoire pour toutes les routes
- Contrôle d'accès par profil (role-based)
- Messages d'erreur explicites

## 📝 Notes

- Chaque page affiche les données EN DIRECT de la base
- Les requêtes respectent les droits MySQL Phase 4
- Les vues Phase 3 sont exploitées correctement
- Interface simple et responsive

## 🎓 Niveau : DÉCOUVERTE

Cette implémentation suit le guide "Niveau Découverte" avec:
- Architecture guidée par les endpoints du sujet
- Authentification applicative (Option B)
- Stack : Node.js + Express + MySQL2

---
**Groupe:** Khallouk, Leblanc, Shaaban  
**Phase:** 5 - Interfaces  
**Date:** 2026-06-01
