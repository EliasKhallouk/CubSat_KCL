const express = require('express');
const router = express.Router();
const pool = require('../db');

// Middleware pour vérifier l'authentification
const checkAuth = (req, res, next) => {
  if (!req.session.user) {
    return res.redirect('/api/auth/login');
  }
  next();
};

// GET satellites (FO-01)
router.get('/satellites', checkAuth, async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query('SELECT * FROM VUE_SATELLITES_OPERATIONNELS');
    connection.release();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET communications (FO-02)
router.get('/communications', checkAuth, async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query('SELECT * FROM VUE_BILAN_COMMUNICATIONS ORDER BY volume_total DESC');
    connection.release();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET missions (FO-03)
router.get('/missions', checkAuth, async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query('SELECT * FROM VUE_TABLEAU_DE_BORD_MISSIONS');
    connection.release();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET alerts (FO-04)
router.get('/alerts', checkAuth, async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query('SELECT * FROM VUE_ALERTES_INSTRUMENTS ORDER BY priorite DESC');
    connection.release();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
