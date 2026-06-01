const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');
require('dotenv').config();

// Mapping des profils utilisateurs MySQL
const ROLE_MAPPING = {
  'analyste_data': 'analyste',
  'operateur_sat': 'operateur',
  'resp_mission': 'responsable',
  'admin_nano': 'admin',
};

// GET login page
router.get('/login', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>NanoOrbit - Connexion</title>
      <style>
        body { font-family: Arial; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
        .login-box { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); width: 300px; }
        h1 { text-align: center; color: #333; }
        input, button { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; font-size: 14px; }
        button { background: #007bff; color: white; border: none; cursor: pointer; }
        button:hover { background: #0056b3; }
        .error { color: red; text-align: center; margin-bottom: 10px; }
        .hint { font-size: 12px; color: #666; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="login-box">
        <h1>🛰️ NanoOrbit</h1>
        <form method="POST" action="/api/auth/login">
          <input type="text" name="username" placeholder="Utilisateur" required>
          <input type="password" name="password" placeholder="Mot de passe" required>
          <button type="submit">Connexion</button>
        </form>
        <div class="hint">
          <strong>Comptes de test :</strong><br>
          analyste_data / Analyste123!<br>
          operateur_sat / Operateur123!<br>
          resp_mission / Mission123!<br>
          admin_nano / Admin123!
        </div>
      </div>
    </body>
    </html>
  `);
});

// POST login - Option A : Authentification MySQL réelle
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  // Vérifier que le compte existe dans notre mapping
  if (!ROLE_MAPPING[username]) {
    return res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Erreur de connexion</title>
        <style>
          body { font-family: Arial; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
          .box { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
          .error { color: red; margin-bottom: 20px; }
          a { color: #007bff; text-decoration: none; }
        </style>
      </head>
      <body>
        <div class="box">
          <p class="error">❌ Identifiants incorrects</p>
          <a href="/api/auth/login">← Retour</a>
        </div>
      </body>
      </html>
    `);
  }

  try {
    // Essayer de se connecter à MariaDB avec les identifiants fournis
    const pool = mysql.createPool({
      host: process.env.DB_HOST,
      user: username,
      password: password,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 1,
      queueLimit: 0
    });

    const connection = await pool.getConnection();
    await connection.query('SELECT 1');
    connection.release();
    await pool.end();

    // Connexion réussie : créer la session
    req.session.user = username;
    req.session.role = ROLE_MAPPING[username];
    res.redirect('/app');

  } catch (error) {
    // Identifiants incorrects ou erreur de connexion
    return res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Erreur de connexion</title>
        <style>
          body { font-family: Arial; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
          .box { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
          .error { color: red; margin-bottom: 20px; }
          a { color: #007bff; text-decoration: none; }
        </style>
      </head>
      <body>
        <div class="box">
          <p class="error">❌ Identifiants incorrects</p>
          <a href="/api/auth/login">← Retour</a>
        </div>
      </body>
      </html>
    `);
  }
});

// GET logout
router.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/api/auth/login');
});

module.exports = router;
