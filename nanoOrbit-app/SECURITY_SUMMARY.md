# 🔐 Résumé de sécurité - Gestion des droits utilisateurs

## ✅ Implémentation complète

### Architecture multiniveaux

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. FRONTEND (Navigation contrôlée)                              │
│    - analyste : voit seulement Front-office                     │
│    - operateur : Front + BO Satellites                          │
│    - resp_mission : Front + BO Missions                         │
│    - admin : Front + BO Complet                                 │
├─────────────────────────────────────────────────────────────────┤
│ 2. MIDDLEWARE (Vérification des rôles)                          │
│    checkRole(['operateur', 'admin']) ← Accepte une liste       │
│    → Retourne 403 si rôle non autorisé                          │
├─────────────────────────────────────────────────────────────────┤
│ 3. UTILISATEUR SPÉCIFIQUE (Identifiants de session)             │
│    - Session stocke: dbUser, dbPassword de l'utilisateur        │
│    - Requête exécutée AVEC LES DROITS DE L'UTILISATEUR          │
│    - MariaDB applique les restrictions automatiquement          │
├─────────────────────────────────────────────────────────────────┤
│ 4. MARIADB (Contrôle d'accès natif)                             │
│    - analyste_data : SELECT uniquement                          │
│    - operateur_sat : SELECT + FENETRE_COM + SATELLITE status    │
│    - resp_mission : SELECT + MISSION + PARTICIPATION            │
│    - admin_nano : ALL PRIVILEGES                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Checklist de sécurité

### Authentification
- [x] Connexion via identifiants MariaDB réels
- [x] Pas de secrets en dur dans le code
- [x] Identifiants stockés dans la session (chiffré par Express)
- [x] Erreurs génériques (pas de révélation d'info)

### Autorisation (Front-end)
- [x] Menu d'administration caché si analyste_data
- [x] Formulaires BO-01, BO-02, BO-03, BO-04 visibles selon rôle
- [x] Boutons de soumission désactivés au besoin

### Autorisation (Middleware)
- [x] checkAuth() vérifie req.session.user
- [x] checkRole(['role1', 'role2']) sur chaque route protégée
- [x] Retourne 403 Forbidden si rôle insuffisant
- [x] BO-01 (Statut) : checkRole(['operateur', 'admin'])
- [x] BO-02 (Fenêtres) : checkRole(['operateur', 'admin'])
- [x] BO-03 (Missions) : checkRole(['responsable', 'admin'])
- [x] BO-04 (Désorbite) : checkRole(['admin']) uniquement

### Autorisation (Base de données)
- [x] Chaque requête utilise getUserConnection(session)
- [x] Pool créé avec les identifiants de l'utilisateur connecté
- [x] MariaDB applique les droits definis en Phase 4
- [x] Impossibilité de contourner les droits MariaDB

### Gestion des erreurs
- [x] Erreur connexion → "Identifiants incorrects"
- [x] Rôle insuffisant → "Accès refusé pour votre profil"
- [x] Erreur requête → message générique (pas de SQL exposé)

---

## 🎯 Scénarios de test

### Test 1: analyste_data (lecture seule)
```bash
# ✅ Peut faire
GET /api/front/satellites
GET /api/front/communications
GET /api/front/missions
GET /api/front/alerts

# ❌ Impossible
POST /api/back/satellites/1/statut → 403 Forbidden
POST /api/back/fenetres → 403 Forbidden
```

### Test 2: operateur_sat (satellites + fenêtres)
```bash
# ✅ Peut faire
POST /api/back/satellites/1/statut → OK
POST /api/back/fenetres → OK

# ❌ Impossible
POST /api/back/participations → 403 Forbidden
POST /api/back/satellites/1/deorbit → 403 Forbidden
```

### Test 3: resp_mission (missions + participations)
```bash
# ✅ Peut faire
POST /api/back/participations → OK

# ❌ Impossible
POST /api/back/satellites/1/statut → 403 Forbidden
POST /api/back/fenetres → 403 Forbidden
POST /api/back/satellites/1/deorbit → 403 Forbidden
```

### Test 4: admin_nano (accès complet)
```bash
# ✅ Peut faire (tout)
POST /api/back/satellites/1/statut → OK
POST /api/back/fenetres → OK
POST /api/back/participations → OK
POST /api/back/satellites/1/deorbit → OK
```

---

## 📊 Fichiers de sécurité

| Fichier | Rôle |
|---------|------|
| `routes/auth.js` | Authentification via MariaDB + stockage session |
| `db-user.js` | Connexion avec identifiants utilisateur |
| `routes/front.js` | Lecture seule, utilise getUserConnection() |
| `routes/back.js` | Écriture protégée, checkRole() + getUserConnection() |

---

## ✨ Points forts

1. **Double sécurité** : Middleware + MariaDB
2. **Pas de bypass possible** : Même si middleware était contourné, MariaDB refuse
3. **Audit trail** : Chaque requête vient d'un utilisateur identifié
4. **Pas de secrets en dur** : Identifiants en session chiffrée
5. **Respect Phase 4** : Droits MySQL appliqués automatiquement

---

## 🚀 Déploiement

Avant de mettre en production:

1. Changer `SESSION_SECRET` dans `.env`
   ```
   SESSION_SECRET=générer-une-clé-longue-et-complexe
   ```

2. Vérifier que MariaDB a les droits Phase 4 appliqués

3. Tester chaque profil avec les scénarios ci-dessus

4. Activer HTTPS en production (secrets en transit)

---

**Statut:** ✅ Sécurité complète implémentée  
**Phase:** 5 - Interfaces Applicatives  
**Date:** 2026-06-01
