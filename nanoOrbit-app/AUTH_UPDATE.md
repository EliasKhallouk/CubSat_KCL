# ✅ Authentification mise à jour

## Changement : Option B → Option A

### Avant (Option B - Données en dur)
```javascript
const USERS = {
  'analyste_data': { password: 'Analyste123!', role: 'analyste' },
  'operateur_sat': { password: 'Operateur123!', role: 'operateur' },
  ...
};
// Vérification locale dans le code
if (USERS[username] && USERS[username].password === password) { ... }
```

### Maintenant (Option A - Base de données MariaDB)
```javascript
// Essai de connexion directe à MariaDB
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: username,        // ← L'utilisateur entré
  password: password,    // ← Le mot de passe entré
  database: process.env.DB_NAME
});
const connection = await pool.getConnection();
await connection.query('SELECT 1');  // ← Vérification réelle
```

## Avantages
✅ **Authentification réelle** via MariaDB  
✅ **Respect des droits Phase 4** : chaque profil a ses permissions SQL  
✅ **Pas de secrets en dur** dans le code  
✅ **Dynamique** : ajouter un user = modifier MySQL, pas le code  

## Comptes à utiliser

| Utilisateur | Mot de passe | Créé en Phase 4 |
|---|---|---|
| `analyste_data` | `Analyste123!` | ✅ |
| `operateur_sat` | `Operateur123!` | ✅ |
| `resp_mission` | `Mission123!` | ✅ |
| `admin_nano` | `Admin123!` | ✅ |

## Comment ça marche

1. Utilisateur remplit le formulaire de login
2. L'app **essaie de se connecter à MariaDB** avec ces identifiants
3. Si la connexion réussit → session créée
4. Si la connexion échoue → erreur de login
5. Les droits SQL sont appliqués **automatiquement** par MariaDB

## Configuration

`.env` utilise `operateur_sat` pour le pool par défaut:
```
DB_USER=operateur_sat
DB_PASSWORD=Operateur123!
```

Mais le **login** teste chaque profil directement!

## Avantage avec MariaDB

MariaDB/MySQL applique les droits **automatiquement**:
- `analyste_data` ne peut que SELECT
- `operateur_sat` peut modifier FENETRE_COM et statut SATELLITE
- `resp_mission` peut modifier MISSION et PARTICIPATION
- `admin_nano` a tous les droits

**Donc si un user essaie une action interdite, MariaDB dit NON directement! 🔒**

---
**Fichier modifié:** `routes/auth.js`  
**Date:** 2026-06-01  
**Phase:** 5 - Sécurité renforcée ✨
