# 🚀 Guide de démarrage rapide - Phase 5

## Étape 1 : Vérifier la base de données

Assurez-vous que votre base `nanoOrbit_db` est bien créée avec les phases 1-4:

```bash
mysql -u root -p
mysql> USE nanoOrbit_db;
mysql> SHOW TABLES;
mysql> SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

## Étape 2 : Démarrer l'application

```bash
cd /home/elias/A4/BDD/CubSat_KCL/nanoOrbit-app
npm install  # si première fois
npm start
```

**Résultat attendu:**
```
✅ NanoOrbit app listening on http://localhost:3000
📍 Login: http://localhost:3000/api/auth/login
```

## Étape 3 : Accéder à l'application

Ouvrez votre navigateur: **http://localhost:3000/api/auth/login**

## Étape 4 : Comptes de test

| Compte | Mot de passe | Accès |
|--------|---|---|
| `analysite_data` | `Analyste123!` | Front-office seulement |
| `operateur_sat` | `Operateur123!` | Front + Back (satellites) |
| `resp_mission` | `Mission123!` | Front + Back (missions) |
| `admin_nano` | `Admin123!` | Accès complet |

## Étape 5 : Tester les onglets

1. **Satellites** : Vue des satellites opérationnels
2. **Communications** : Résumé par satellite
3. **Missions** : État des missions
4. **Alertes** : Instruments en anomalie
5. **Administration** : Formulaires (si autorisé)

## 🔧 Configuration

Modifiez `.env` pour changer:
- `DB_HOST` : localhost
- `DB_USER` : operateur_sat
- `DB_PASSWORD` : Operateur123!
- `DB_NAME` : nanoOrbit_db
- `PORT` : 3000

---
**Bon développement! 🚀**
