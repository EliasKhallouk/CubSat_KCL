require('dotenv').config();
const express = require('express');
const session = require('express-session');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(session({
  secret: process.env.SESSION_SECRET || 'secret',
  resave: false,
  saveUninitialized: true,
  cookie: { maxAge: 24 * 60 * 60 * 1000 }
}));

app.use(express.static(path.join(__dirname, 'public')));

const authRoutes = require('./routes/auth');
const frontRoutes = require('./routes/front');
const backRoutes = require('./routes/back');

app.use('/api/auth', authRoutes);
app.use('/api/front', frontRoutes);
app.use('/api/back', backRoutes);

app.get('/', (req, res) => {
  if (req.session.user) {
    res.redirect('/app');
  } else {
    res.redirect('/api/auth/login');
  }
});

app.get('/app', (req, res) => {
  if (!req.session.user) {
    return res.redirect('/api/auth/login');
  }
  const username = req.session.user;
  const role = req.session.role;
  res.send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>NanoOrbit - Dashboard</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .navbar { background: #007bff; color: white; padding: 15px 0; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    .navbar h1 { margin-left: 20px; display: inline-block; }
    .user-info { float: right; margin-right: 20px; font-size: 14px; }
    .logout { color: white; text-decoration: none; margin-left: 15px; }
    .tabs { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
    .tab-btn { padding: 10px 20px; background: white; border: 1px solid #ddd; cursor: pointer; border-radius: 4px; font-size: 14px; }
    .tab-btn.active { background: #007bff; color: white; border-color: #007bff; }
    .section { display: none; }
    .section.active { display: block; }
    table { width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-radius: 4px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; font-size: 13px; }
    th { background: #f9f9f9; font-weight: 600; }
    tr:hover { background: #f9f9f9; }
    .badge { padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }
    .badge-1u { background: #e3f2fd; color: #1976d2; }
    .badge-3u { background: #f3e5f5; color: #7b1fa2; }
    .badge-6u { background: #fff3e0; color: #e65100; }
    .badge-12u { background: #e8f5e9; color: #388e3c; }
    .form-group { margin: 15px 0; }
    .form-group label { display: block; margin-bottom: 5px; font-weight: 600; font-size: 14px; }
    .form-group input, .form-group select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 13px; }
    .form-group button { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; }
    .form-group button:hover { background: #0056b3; }
    .message { padding: 10px; margin: 10px 0; border-radius: 4px; font-size: 14px; }
    .message.success { background: #d4edda; color: #155724; }
    .message.error { background: #f8d7da; color: #721c24; }
    .box { background: white; padding: 20px; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin: 20px 0; }
    h2, h3 { margin: 15px 0; }
  </style>
</head>
<body>
  <div class="navbar">
    <h1>🛰️ NanoOrbit Dashboard</h1>
    <div class="user-info">
      Connecté: <strong>${username}</strong> (${role})
      <a href="/api/auth/logout" class="logout">Déconnexion</a>
    </div>
  </div>

  <div class="container">
    <div class="tabs">
      <button class="tab-btn active" onclick="showTab(event, 'satellites')">🛰️ Satellites</button>
      <button class="tab-btn" onclick="showTab(event, 'communications')">📡 Communications</button>
      <button class="tab-btn" onclick="showTab(event, 'missions')">🎯 Missions</button>
      <button class="tab-btn" onclick="showTab(event, 'alerts')">⚠️ Alertes</button>
      <button class="tab-btn" onclick="showTab(event, 'backoffice')">⚙️ Administration</button>
    </div>

    <div id="satellites" class="section active">
      <h2>Tableau de bord des satellites opérationnels</h2>
      <div id="satellitesContent" style="margin-top: 20px;"></div>
    </div>

    <div id="communications" class="section">
      <h2>Bilan des communications par satellite</h2>
      <div id="communicationsContent" style="margin-top: 20px;"></div>
    </div>

    <div id="missions" class="section">
      <h2>Tableau de bord des missions</h2>
      <div id="missionsContent" style="margin-top: 20px;"></div>
    </div>

    <div id="alerts" class="section">
      <h2>Alertes instruments</h2>
      <div id="alertsCount" style="font-size: 20px; font-weight: bold; color: #d32f2f; margin-bottom: 10px;"></div>
      <div id="alertsContent" style="margin-top: 20px;"></div>
    </div>

    <div id="backoffice" class="section">
      <h2>⚙️ Administration (Back-office)</h2>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 20px;">
        ${['operateur', 'admin'].includes(role) ? `
        <div class="box">
          <h3>Modifier le statut d'un satellite</h3>
          <form onsubmit="updateSatelliteStatus(event)">
            <div class="form-group">
              <label>Satellite:</label>
              <select id="satSelect" required><option>Chargement...</option></select>
            </div>
            <div class="form-group">
              <label>Nouveau statut:</label>
              <select id="statusSelect" required>
                <option value="ACTIF">Actif</option>
                <option value="INACTIF">Inactif</option>
                <option value="HS">Hors service</option>
              </select>
            </div>
            <button type="submit">Mettre à jour</button>
          </form>
          <div id="statusMessage"></div>
        </div>

        <div class="box">
          <h3>Planifier une fenêtre de communication</h3>
          <form onsubmit="createWindow(event)">
            <div class="form-group">
              <label>Satellite:</label>
              <select id="winSatSelect" required><option>Chargement...</option></select>
            </div>
            <div class="form-group">
              <label>Station:</label>
              <select id="stationSelect" required><option>Chargement...</option></select>
            </div>
            <div class="form-group">
              <label>Date/Heure:</label>
              <input type="datetime-local" id="windowStart" required>
            </div>
            <div class="form-group">
              <label>Durée (sec):</label>
              <input type="number" id="windowDuration" min="1" max="900" required>
            </div>
            <div class="form-group">
              <label>Élévation max (°):</label>
              <input type="number" id="elevationMax" min="0" max="90" required>
            </div>
            <button type="submit">Créer fenêtre</button>
          </form>
          <div id="windowMessage"></div>
        </div>
        ` : ''}

        ${['responsable', 'admin'].includes(role) ? `
        <div class="box">
          <h3>Assigner un satellite à une mission</h3>
          <form onsubmit="createParticipation(event)">
            <div class="form-group">
              <label>Satellite:</label>
              <select id="partSatSelect" required><option>Chargement...</option></select>
            </div>
            <div class="form-group">
              <label>Mission:</label>
              <select id="missionSelect" required><option>Chargement...</option></select>
            </div>
            <div class="form-group">
              <label>Rôle du satellite:</label>
              <input type="text" id="roleSatellite" placeholder="Ex: Principal, Support..." required>
            </div>
            <button type="submit">Assigner</button>
          </form>
          <div id="participationMessage"></div>
        </div>
        ` : ''}

        ${role === 'analyste' ? `
        <div class="box"><p style="color:#666; padding: 20px;">Accès lecture seule — aucune action d'administration disponible.</p></div>
        ` : ''}
      </div>
    </div>
  </div>

  <script>
    function showTab(e, tabName) {
      e.preventDefault();
      document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
      document.getElementById(tabName).classList.add('active');
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      
      if (tabName === 'satellites') loadSatellites();
      if (tabName === 'communications') loadCommunications();
      if (tabName === 'missions') loadMissions();
      if (tabName === 'alerts') loadAlerts();
      if (tabName === 'backoffice') loadBackofficeData();
    }

    async function loadSatellites() {
      const res = await fetch('/api/front/satellites');
      const data = await res.json();
      let html = '<table><tr><th>ID</th><th>Nom</th><th>Format</th><th>Date lancement</th><th>Type orbite</th><th>Altitude (km)</th><th>Batterie (Wh)</th></tr>';
      data.forEach(sat => {
        const fmt = (sat.format || sat.FORMAT || '').replace('U', 'u').toLowerCase();
        html += '<tr><td>' + (sat.id_satellite || '') + '</td><td>' + (sat.nom || '') + '</td><td><span class="badge badge-' + fmt + '">' + (sat.format || '') + '</span></td><td>' + (sat.date_lancement || '') + '</td><td>' + (sat.type_orbite || '') + '</td><td>' + (sat.altitude || '') + '</td><td>' + (sat.capacite_batterie || '') + '</td></tr>';
      });
      html += '</table>';
      document.getElementById('satellitesContent').innerHTML = html || '<p>Aucune donnée</p>';
    }

    async function loadCommunications() {
      const res = await fetch('/api/front/communications');
      const data = await res.json();
      let html = '<table><tr><th>Satellite</th><th>Fenêtres</th><th>Volume total (Mo)</th><th>Volume moyen</th><th>Dernière comm.</th><th>Stations</th></tr>';
      data.forEach((com, idx) => {
        const isActive = idx === 0 ? '⭐ ' : '';
        html += '<tr><td><strong>' + isActive + (com.nom_satellite || com.NOM_SATELLITE || '') + '</strong></td><td>' + (com.nb_fenetres || com.NB_FENETRES || 0) + '</td><td>' + (com.volume_total || com.VOLUME_TOTAL || 0) + '</td><td>' + (com.volume_moyen || com.VOLUME_MOYEN || 0) + '</td><td>' + (com.date_derniere || com.DATE_DERNIERE || 'N/A') + '</td><td>' + (com.nb_stations || com.NB_STATIONS || 0) + '</td></tr>';
      });
      html += '</table>';
      document.getElementById('communicationsContent').innerHTML = html || '<p>Aucune donnée</p>';
    }

    async function loadMissions() {
      const res = await fetch('/api/front/missions');
      const data = await res.json();
      let html = '<table><tr><th>ID</th><th>Nom</th><th>Zone</th><th>Début</th><th>Participants</th><th>Opérationnels</th><th>Status</th></tr>';
      data.forEach(mission => {
        const nb_part = mission.nb_satellites_participants || mission.NB_SATELLITES_PARTICIPANTS || 0;
        const nb_op = mission.nb_satellites_operationnels || mission.NB_SATELLITES_OPERATIONNELS || 0;
        const isUnderfunded = nb_part > nb_op;
        const statusColor = isUnderfunded ? '#f57c00' : '#4caf50';
        html += '<tr><td>' + (mission.id_mission || mission.ID_MISSION || '') + '</td><td>' + (mission.nom || mission.NOM || '') + '</td><td>' + (mission.zone_cible || mission.ZONE_CIBLE || '') + '</td><td>' + (mission.date_debut || mission.DATE_DEBUT || '') + '</td><td>' + nb_part + '</td><td>' + nb_op + '</td><td><span style="color: ' + statusColor + '; font-weight: bold;">' + (isUnderfunded ? '⚠️ Sous-dotée' : '✓ OK') + '</span></td></tr>';
      });
      html += '</table>';
      document.getElementById('missionsContent').innerHTML = html || '<p>Aucune donnée</p>';
    }

    async function loadAlerts() {
      const res = await fetch('/api/front/alerts');
      const data = await res.json();
      const critiques = data.filter(a => (a.priorite || a.PRIORITE || '') === 'CRITIQUE').length;
      document.getElementById('alertsCount').innerHTML = '⚠️ ' + critiques + ' alertes critiques';
      
      let html = '<table><tr><th>Satellite</th><th>Instrument</th><th>État</th><th>Priorité</th></tr>';
      data.forEach(alert => {
        const prio = alert.priorite || alert.PRIORITE || '';
        const prioClass = prio === 'CRITIQUE' ? 'alert-critical' : 'alert-surveillance';
        html += '<tr><td>' + (alert.nom_satellite || alert.NOM_SATELLITE || '') + '</td><td>' + (alert.nom_instrument || alert.NOM_INSTRUMENT || '') + '</td><td>' + (alert.etat || alert.ETAT || '') + '</td><td><span class="' + prioClass + '">' + prio + '</span></td></tr>';
      });
      html += '</table>';
      document.getElementById('alertsContent').innerHTML = html || '<p>Aucune donnée</p>';
    }

    async function loadBackofficeData() {
      try {
        console.log('Chargement données back-office...');
        
        const [satsRes, stationsRes, missionsRes] = await Promise.all([
          fetch('/api/back/satellites-operationnels'),
          fetch('/api/back/stations-actives'),
          fetch('/api/back/missions-actives')
        ]);

        if (!satsRes.ok || !stationsRes.ok || !missionsRes.ok) {
          throw new Error('Erreur API: ' + [satsRes.status, stationsRes.status, missionsRes.status].join(', '));
        }

        const sats = await satsRes.json();
        const stations = await stationsRes.json();
        const missions = await missionsRes.json();

        console.log('Satellites:', sats?.length || 0);
        console.log('Stations:', stations?.length || 0);
        console.log('Missions:', missions?.length || 0);

        const satsHtml = (sats || []).map(s => '<option value="' + s.id_satellite + '">' + s.nom + '</option>').join('');
        const stationsHtml = (stations || []).map(s => '<option value="' + s.id_station + '">' + s.nom + '</option>').join('');
        const missionsHtml = (missions || []).map(m => '<option value="' + m.id_mission + '">' + m.nom + '</option>').join('');

        if (document.getElementById('satSelect')) document.getElementById('satSelect').innerHTML = satsHtml || '<option>Aucun satellite</option>';
        if (document.getElementById('winSatSelect')) document.getElementById('winSatSelect').innerHTML = satsHtml || '<option>Aucun satellite</option>';
        if (document.getElementById('stationSelect')) document.getElementById('stationSelect').innerHTML = stationsHtml || '<option>Aucune station</option>';
        if (document.getElementById('partSatSelect')) document.getElementById('partSatSelect').innerHTML = satsHtml || '<option>Aucun satellite</option>';
        if (document.getElementById('missionSelect')) document.getElementById('missionSelect').innerHTML = missionsHtml || '<option>Aucune mission</option>';
      } catch (e) {
        console.error('Erreur loadBackofficeData:', e);
      }
    }

    async function updateSatelliteStatus(e) {
      e.preventDefault();
      const satId = document.getElementById('satSelect').value;
      const statut = document.getElementById('statusSelect').value;
      const res = await fetch('/api/back/satellites/' + satId + '/statut', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ statut })
      });
      const result = await res.json();
      const msgDiv = document.getElementById('statusMessage');
      msgDiv.className = 'message ' + (res.ok ? 'success' : 'error');
      msgDiv.innerHTML = result.message || result.error;
    }

    async function createWindow(e) {
      e.preventDefault();
      const res = await fetch('/api/back/fenetres', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id_satellite: document.getElementById('winSatSelect').value,
          id_station: document.getElementById('stationSelect').value,
          date_debut: document.getElementById('windowStart').value,
          duree: parseInt(document.getElementById('windowDuration').value),
          elevation_max: parseFloat(document.getElementById('elevationMax').value)
        })
      });
      const result = await res.json();
      const msgDiv = document.getElementById('windowMessage');
      msgDiv.className = 'message ' + (res.ok ? 'success' : 'error');
      msgDiv.innerHTML = result.message || result.error;
    }

    async function createParticipation(e) {
      e.preventDefault();
      const res = await fetch('/api/back/participations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id_satellite: document.getElementById('partSatSelect').value,
          id_mission: document.getElementById('missionSelect').value,
          role_satellite: document.getElementById('roleSatellite').value
        })
      });
      const result = await res.json();
      const msgDiv = document.getElementById('participationMessage');
      msgDiv.className = 'message ' + (res.ok ? 'success' : 'error');
      msgDiv.innerHTML = result.message || result.error;
    }

    loadSatellites();
  </script>
</body>
</html>`);
});

app.get('/health', async (req, res) => {
  try {
    const connection = await require('./db').getConnection();
    const [result] = await connection.query('SELECT 1');
    connection.release();
    res.json({ status: 'OK', database: 'Connected' });
  } catch (error) {
    res.status(500).json({ status: 'ERROR', message: error.message });
  }
});

app.listen(PORT, () => {
  console.log('✅ NanoOrbit app listening on http://localhost:' + PORT);
  console.log('📍 Login: http://localhost:' + PORT + '/api/auth/login');
});
