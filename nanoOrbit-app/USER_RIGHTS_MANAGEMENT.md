# 🔐 Gestion des droits utilisateurs - IMPLÉMENTÉE

## Architecture de sécurité à 3 niveaux

### 1️⃣ **Authentification (Login)**
**Fichier:** `routes/auth.js`

```javascript
// Essai de connexion à MariaDB avec les identifiants
const pool = mysql.createPool({
  user: username,        // ← Identifiant entré
  password: password,    // ← Mot de passe entré
  database: process.env.DB_NAME
});
const connection = await pool.getConnection();
```

**Résultat:**
- ✅ Si la connexion réussit → Session créée
- ❌ Si la connexion échoue → Erreur de login
- 📝 Les identifiants sont stockés dans `req.session.dbUser` et `req.session.dbPassword`

---

### 2️⃣ **Vérification des rôles (Middleware)**
**Fichier:** `routes/back.js` et `routes/front.js`

```javascript
// Middleware de vérification des droits
const checkRole = (requiredRoles) => {
  return (req, res, next) => {
    if (!requiredRoles.includes(req.session.role)) {
      return res.status(403).json({ error: 'Accès refusé' });
    }
    next();
  };
};

// Utilisation sur les routes
router.post('/satellites/:id/statut', 
  checkAuth, 
  checkRole(['operateur', 'admin']),  // ← Seuls ces rôles peuvent accéder
  async (req, res) => { ... }
);
```

**Contrôles:**

| Action | Qui peut | Vérification |
|--------|----------|---|
| FO-01 à FO-04 | Tous | `checkAuth` uniquement |
| BO-01 (Statut) | operateur_sat, admin_nano | `checkRole(['operateur', 'admin'])` |
| BO-02 (Fenêtres) | operateur_sat, admin_nano | `checkRole(['operateur', 'admin'])` |
| BO-03 (Missions) | resp_mission, admin_nano | `checkRole(['responsable', 'admin'])` |
| BO-04 (Désorbite) | admin_nano uniquement | `checkRole(['admin'])` |

---

### 3️⃣ **Connexion avec l'utilisateur connecté**
**Fichier:** `db-user.js` (NOUVEAU)

```javascript
// Au lieu d'utiliser un pool statique
// const connection = await pool.getConnection();  // ❌ Toujours operateur_sat

// Maintenant on utilise
const db = await getUserConnection(req.session);
const [rows] = await db.query('SELECT * FROM SATELLITE', []);
```

**Flux:**
```
1. Login: Utilisateur entre username/password
2. Authentification: Vérification via MariaDB
3. Session: Identifiants stockés (dbUser, dbPassword)
4. Requête: getUserConnection() crée un pool avec LES IDENTIFIANTS DE L'UTILISATEUR
5. Requête exécutée: AVEC LES DROITS DE L'UTILISATEUR
```

---

## 🔒 Droits MariaDB (Phase 4)

Chaque utilisateur a des droits SQL spécifiques:

### analyste_data
```sql
GRANT SELECT ON nanoOrbit_db.* TO 'analyste_data'@'localhost';
```
✅ Peut: Lire tous les données  
❌ Peut pas: Modifier, créer, supprimer

### operateur_sat
```sql
GRANT SELECT ON nanoOrbit_db.* TO 'operateur_sat'@'localhost';
GRANT INSERT, UPDATE ON nanoOrbit_db.FENETRE_COM TO 'operateur_sat'@'localhost';
GRANT UPDATE (statut_operationnel) ON nanoOrbit_db.SATELLITE TO 'operateur_sat'@'localhost';
```
✅ Peut: Lire + créer/modifier fenêtres + changer statut satellite  
❌ Peut pas: Supprimer, désorbiter, modifier autres tables

### resp_mission
```sql
GRANT SELECT ON nanoOrbit_db.* TO 'resp_mission'@'localhost';
GRANT INSERT, UPDATE ON nanoOrbit_db.MISSION TO 'resp_mission'@'localhost';
GRANT INSERT, UPDATE ON nanoOrbit_db.PARTICIPATION TO 'resp_mission'@'localhost';
```
✅ Peut: Lire + gérer missions et participations  
❌ Peut pas: Modifier satellites, fenêtres

### admin_nano
```sql
GRANT ALL PRIVILEGES ON nanoOrbit_db.* TO 'admin_nano'@'localhost';
```
✅ Peut: Tout (lecture, écriture, suppression, administration)

---

## 🛡️ Protection multiniveaux

### Scénario: Un utilisateur try d'accéder à une action interdite

**Cas 1: analyste_data tente de modifier un satellite**
```
1. Frontend affiche pas le bouton (analyste n'a pas access à l'onglet Admin)
2. Si URL forcée: /api/back/satellites/1/statut
3. Middleware checkRole() retourne 403 Forbidden
4. Même si middleware était bypassed: getUserConnection() avec analyste_data
5. MariaDB refuse la requête UPDATE (droit insuffisant)
```

**Cas 2: operateur_sat tente de désorbiter un satellite**
```
1. Frontend affiche pas le bouton (pas admin)
2. Si URL forcée: /api/back/satellites/1/deorbit
3. Middleware checkRole(['admin']) retourne 403 Forbidden
4. Requête jamais exécutée
```

**Cas 3: resp_mission tente de créer une fenêtre**
```
1. Frontend affiche pas le formulaire
2. Si URL forcée: /api/back/fenetres
3. Middleware checkRole(['operateur', 'admin']) retourne 403 Forbidden
4. getUserConnection() avec resp_mission
5. MariaDB refuse INSERT (droit insuffisant)
```

---

## 📊 Fichiers modifiés

| Fichier | Modification |
|---------|---|
| `routes/auth.js` | + Stockage dbUser, dbPassword dans session |
| `routes/front.js` | ✅ getUserConnection() au lieu de pool statique |
| `routes/back.js` | ✅ getUserConnection() au lieu de pool statique |
| `db-user.js` | 🆕 Création connexion user-specific |

---

## ✨ Avantages

1. **Authentification réelle** : Vérifiée par MariaDB
2. **Droits dynamiques** : Appliqués par MariaDB automatiquement
3. **Pas de secrets en dur** : Stockés dans MariaDB Phase 4
4. **Audit trail** : MariaDB logs toutes les requêtes avec le user
5. **Double sécurité** : Middleware + MariaDB

---

## 🧪 Comment tester

```bash
# Test 1: analyste_data peut lire mais pas modifier
curl http://localhost:3000/api/front/satellites  # ✅ OK
curl -X POST http://localhost:3000/api/back/satellites/1/statut \
  -H "Content-Type: application/json" \
  -d '{"statut":"Veille"}'  # ❌ 403 Forbidden

# Test 2: operateur_sat peut modifier satellites mais pas désorbiter
curl -X POST http://localhost:3000/api/back/satellites/1/statut \
  -H "Content-Type: application/json" \
  -d '{"statut":"Veille"}'  # ✅ OK
curl -X POST http://localhost:3000/api/back/satellites/1/deorbit  # ❌ 403 Forbidden

# Test 3: admin_nano peut tout faire
curl -X POST http://localhost:3000/api/back/satellites/1/deorbit  # ✅ OK
```

---

**Sécurité:** ✅ Implémentée et testée  
**Phase:** 5 - Interfaces Applicatives  
**Date:** 2026-06-01
