const express = require('express');
const router = express.Router();
const { getUserConnection } = require('../db-user');

// Middleware pour vérifier l'authentification
const checkAuth = (req, res, next) => {
  if (!req.session.user) {
    return res.status(401).json({ error: 'Non authentifié' });
  }
  next();
};

// Middleware pour vérifier les droits
const checkRole = (requiredRoles) => {
  return (req, res, next) => {
    if (!requiredRoles.includes(req.session.role)) {
      return res.status(403).json({ error: 'Accès refusé pour votre profil' });
    }
    next();
  };
};

// BO-01: Modifier le statut d'un satellite (operateur_sat, admin_nano)
router.post('/satellites/:id/statut', checkAuth, checkRole(['operateur', 'admin']), async (req, res) => {
  try {
    const { statut } = req.body;
    const { id } = req.params;
    
    if (!['Opérationnel', 'En veille', 'Désorbité'].includes(statut)) {
      return res.status(400).json({ error: 'Statut invalide' });
    }

    const db = await getUserConnection(req.session);
    await db.query('UPDATE SATELLITE SET statut_operationnel = ? WHERE id_satellite = ?', [statut, id]);
    await db.release();
    
    res.json({ success: true, message: `Satellite ${id} mis à jour: ${statut}` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// BO-02: Planifier une fenêtre de communication (operateur_sat, admin_nano)
router.post('/fenetres', checkAuth, checkRole(['operateur', 'admin']), async (req, res) => {
  try {
    const { id_satellite, id_station, date_debut, duree, elevation_max } = req.body;
    
    if (duree < 1 || duree > 900) {
      return res.status(400).json({ error: 'Durée invalide (1-900 secondes)' });
    }

    const db = await getUserConnection(req.session);
    await db.query(
      'INSERT INTO FENETRE_COM (id_satellite, id_station, date_debut, duree, elevation_max, statut) VALUES (?, ?, ?, ?, ?, ?)',
      [id_satellite, id_station, date_debut, duree, elevation_max, 'Planifiée']
    );
    await db.release();
    
    res.json({ success: true, message: 'Fenêtre de communication créée' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// BO-03: Assigner un satellite à une mission (resp_mission, admin_nano)
router.post('/participations', checkAuth, checkRole(['responsable', 'admin']), async (req, res) => {
  try {
    const { id_satellite, id_mission, role_satellite } = req.body;
    
    const db = await getUserConnection(req.session);
    
    // Vérifier que la mission n'est pas terminée
    const [missions] = await db.query('SELECT date_fin FROM MISSION WHERE id_mission = ?', [id_mission]);
    if (missions[0] && missions[0].date_fin && new Date(missions[0].date_fin) < new Date()) {
      await db.release();
      return res.status(400).json({ error: 'Mission terminée' });
    }
    
    // Vérifier que la participation n'existe pas
    const [existing] = await db.query(
      'SELECT * FROM PARTICIPATION WHERE id_satellite = ? AND id_mission = ?',
      [id_satellite, id_mission]
    );
    
    if (existing.length > 0) {
      await db.release();
      return res.status(400).json({ error: 'Satellite déjà assigné à cette mission' });
    }
    
    await db.query(
      'INSERT INTO PARTICIPATION (id_satellite, id_mission, role_satellite) VALUES (?, ?, ?)',
      [id_satellite, id_mission, role_satellite]
    );
    await db.release();
    
    res.json({ success: true, message: 'Satellite assigné à la mission' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// BO-04: Désorbiter un satellite (admin_nano uniquement)
router.post('/satellites/:id/deorbit', checkAuth, checkRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    const db = await getUserConnection(req.session);
    await db.query('UPDATE SATELLITE SET statut_operationnel = ? WHERE id_satellite = ?', ['Désorbité', id]);
    await db.release();
    
    res.json({ success: true, message: `Satellite ${id} désorbité` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET dropdown data pour les formulaires - utilise pool par défaut (lecture)
router.get('/satellites-operationnels', checkAuth, async (req, res) => {
  try {
    const db = await getUserConnection(req.session);
    const [rows] = await db.query('SELECT id_satellite, nom FROM SATELLITE WHERE statut_operationnel IN ("Opérationnel", "operationnel", "OPERATIONNEL")', []);
    await db.release();
    res.json(rows || []);
  } catch (error) {
    console.error('Erreur satellites-operationnels:', error.message);
    res.status(500).json({ error: error.message });
  }
});

router.get('/stations-actives', checkAuth, async (req, res) => {
  try {
    const db = await getUserConnection(req.session);
    const [rows] = await db.query('SELECT id_station, nom FROM STATION_SOL WHERE etat IN ("Active", "active", "ACTIVE")', []);
    await db.release();
    res.json(rows || []);
  } catch (error) {
    console.error('Erreur stations-actives:', error.message);
    res.status(500).json({ error: error.message });
  }
});

router.get('/missions-actives', checkAuth, async (req, res) => {
  try {
    const db = await getUserConnection(req.session);
    const [rows] = await db.query('SELECT id_mission, nom FROM MISSION WHERE date_fin IS NULL OR date_fin > NOW()', []);
    await db.release();
    res.json(rows || []);
  } catch (error) {
    console.error('Erreur missions-actives:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
