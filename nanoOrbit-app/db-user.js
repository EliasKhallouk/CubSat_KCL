require('dotenv').config();
const mysql = require('mysql2/promise');

/**
 * Obtient une connexion MySQL avec les identifiants de l'utilisateur connecté
 * @param {Object} session - req.session contenant dbUser et dbPassword
 * @returns {Promise<Connection>} Connexion MySQL authentifiée
 */
async function getUserConnection(session) {
  if (!session.dbUser || !session.dbPassword) {
    throw new Error('Utilisateur non authentifié');
  }

  const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: session.dbUser,
    password: session.dbPassword,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 1,
    queueLimit: 0
  });

  const connection = await pool.getConnection();
  
  // Retourner un objet qui contient la connexion et le pool pour pouvoir les fermer
  return {
    query: async (sql, values) => connection.query(sql, values),
    release: async () => {
      connection.release();
      await pool.end();
    }
  };
}

module.exports = { getUserConnection };
