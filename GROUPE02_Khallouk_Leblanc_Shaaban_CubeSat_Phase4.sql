/* PARTIE 1 — CONFIGURATION INITIALE */

-- E2.1 - Création des utilisateurs

-- operateur_sat :
-- Technicien chargé du suivi quotidien des satellites.
-- Il doit pouvoir consulter les données et intervenir sur les opérations courantes.
CREATE USER IF NOT EXISTS 'operateur_sat'@'localhost' IDENTIFIED BY 'Operateur123!';

-- analyste_data :
-- Data scientist qui analyse les données.
-- Il n'a besoin que d’un accès en lecture, sans modification.
CREATE USER IF NOT EXISTS 'analyste_data'@'localhost' IDENTIFIED BY 'Analyste123!';

-- resp_mission :
-- Responsable de la planification des missions.
-- Il manipule uniquement les données liées aux missions et participations.
CREATE USER IF NOT EXISTS 'resp_mission'@'localhost' IDENTIFIED BY 'Mission123!';

-- admin_nano :
-- Administrateur technique.
-- Il a une vision globale et doit pouvoir gérer toutes les données.
CREATE USER IF NOT EXISTS 'admin_nano'@'localhost' IDENTIFIED BY 'Admin123!';


-- E2.2 - Vérification
-- Permet de vérifier que les utilisateurs ont bien été créés.
SELECT user, host FROM mysql.user;



/* PARTIE 2 — INCIDENT SÉCURITÉ */

-- E3.1 - Analyste données (lecture seule)

-- L'analyste doit uniquement lire les données pour produire des rapports.
-- Aucun droit de modification pour éviter toute altération des données.
GRANT SELECT 
ON nanoOrbit_db.* 
TO 'analyste_data'@'localhost';

-- Vérification des droits attribués
SHOW GRANTS FOR 'analyste_data'@'localhost';



-- E3.2 - Opérateur satellite

-- L'opérateur doit consulter toutes les données pour suivre les satellites.
GRANT SELECT 
ON nanoOrbit_db.* 
TO 'operateur_sat'@'localhost';

-- Il peut créer et modifier les fenêtres de communication (actions opérationnelles quotidiennes).
GRANT INSERT, UPDATE 
ON nanoOrbit_db.FENETRE_COM 
TO 'operateur_sat'@'localhost';

-- Il peut uniquement modifier le statut opérationnel des satellites,
-- sans toucher aux autres attributs critiques.
GRANT UPDATE (statut_operationnel)
ON nanoOrbit_db.SATELLITE
TO 'operateur_sat'@'localhost';



-- E3.3 - Responsable missions

-- Le responsable doit consulter les données globales pour planifier.
GRANT SELECT 
ON nanoOrbit_db.* 
TO 'resp_mission'@'localhost';

-- Il peut créer et modifier les missions.
GRANT INSERT, UPDATE 
ON nanoOrbit_db.MISSION 
TO 'resp_mission'@'localhost';

-- Il gère aussi les participations (assignation des satellites aux missions).
GRANT INSERT, UPDATE 
ON nanoOrbit_db.PARTICIPATION 
TO 'resp_mission'@'localhost';

-- Aucun droit sur SATELLITE ou ORBITE pour éviter toute modification technique.



-- E3.4 - Administrateur technique

-- L'administrateur a un contrôle complet sur les données.
-- Il peut lire, modifier, ajouter et supprimer des enregistrements.
GRANT SELECT, INSERT, UPDATE, DELETE 
ON nanoOrbit_db.* 
TO 'admin_nano'@'localhost';

-- Il peut également créer des vues pour organiser et sécuriser l’accès aux données.
GRANT CREATE VIEW 
ON nanoOrbit_db.* 
TO 'admin_nano'@'localhost';


-- Appliquer les droits
-- Rend effectifs tous les privilèges attribués.
FLUSH PRIVILEGES;



/* PARTIE 3 — RÉORGANISATION */

-- E4.1

-- On retire à l’opérateur le droit de modifier le statut des satellites.
-- Cela peut correspondre à un changement d’organisation ou à une restriction de sécurité.
REVOKE UPDATE (statut_operationnel)
ON nanoOrbit_db.SATELLITE
FROM 'operateur_sat'@'localhost';

-- Vérification des nouveaux droits
SHOW GRANTS FOR 'operateur_sat'@'localhost';


-- E4.2

-- On retire tous les droits de l’analyste.
-- Utile si son accès doit être suspendu temporairement ou avant suppression.
REVOKE ALL PRIVILEGES 
ON nanoOrbit_db.* 
FROM 'analyste_data'@'localhost';

-- Suppression complète du compte utilisateur.
-- L’analyste ne pourra plus se connecter du tout.
DROP USER 'analyste_data'@'localhost';

-- Vérification de la suppression
SELECT user, host FROM mysql.user;


-- E4.3 

-- REVOKE ALL PRIVILEGES :
-- retire les droits mais conserve le compte
-- utile pour une désactivation temporaire

-- DROP USER :
-- supprime définitivement le compte
-- utilisé lorsqu’un utilisateur quitte l’organisation



/* PARTIE 4 — MANIPULATION DE VUES */

-- E5.1

-- Création d’une vue publique sur les satellites.
-- Permet de masquer les données sensibles et simplifier l’accès.
CREATE OR REPLACE VIEW VUE_SATELLITES_PUBLIQUE AS
SELECT 
    s.id_satellite,
    s.nom_satellite,
    s.format_cubesat,
    s.statut_operationnel AS statut,
    o.type_orbite
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite;


-- E5.3

-- Vue sur les missions en cours avec le nombre de satellites impliqués.
-- Permet à l’analyste d’obtenir une information agrégée sans accès direct aux tables.
CREATE OR REPLACE VIEW VUE_MISSIONS_PUBLIQUE AS
SELECT 
    m.id_mission,
    m.nom_mission,
    COUNT(p.id_satellite) AS nb_satellites
FROM MISSION m
JOIN PARTICIPATION p ON m.id_mission = p.id_mission
WHERE m.statut = 'EN_COURS'
GROUP BY m.id_mission, m.nom_mission;


-- E5.2

-- Recréation de l’analyste avec accès restreint

-- L’utilisateur est recréé après suppression.
CREATE USER IF NOT EXISTS 'analyste_data'@'localhost' 
IDENTIFIED BY 'Analyste123!';

-- Il n’a accès qu’aux vues (et non aux tables brutes),
-- ce qui renforce la sécurité et limite les risques.
GRANT SELECT 
ON nanoOrbit_db.VUE_SATELLITES_PUBLIQUE 
TO 'analyste_data'@'localhost';

GRANT SELECT 
ON nanoOrbit_db.VUE_MISSIONS_PUBLIQUE 
TO 'analyste_data'@'localhost';


-- Vérification :

-- L’analyste peut consulter les vues…
-- SELECT * FROM VUE_SATELLITES_PUBLIQUE;

-- …mais pas les tables directement
-- SELECT * FROM SATELLITE;  --> refusé

-- Cela garantit une séparation claire entre données brutes et données exploitées.


/* MISE EN SITUATION */

-- =====================================================
-- MISSION 1 — CONFIGURATION INITIALE
-- =====================================================

-- CREATE USERS

-- operateur_sat :
-- Technicien en charge du suivi des satellites.
-- Il intervient sur les opérations quotidiennes.
CREATE USER IF NOT EXISTS 'operateur_sat'@'localhost' IDENTIFIED BY 'Operateur123!';

-- analyste_data :
-- Data scientist chargé d’analyser les données.
-- Il n’a besoin que d’un accès en lecture.
CREATE USER IF NOT EXISTS 'analyste_data'@'localhost' IDENTIFIED BY 'Analyste123!';

-- resp_mission :
-- Responsable de la planification des missions.
-- Il manipule uniquement les données métier liées aux missions.
CREATE USER IF NOT EXISTS 'resp_mission'@'localhost' IDENTIFIED BY 'Mission123!';

-- admin_nano :
-- Administrateur technique.
-- Il gère l’ensemble du système et des données.
CREATE USER IF NOT EXISTS 'admin_nano'@'localhost' IDENTIFIED BY 'Admin123!';


-- =====================================================
-- ANALYSTE DATA (lecture seule)
-- =====================================================

-- L’analyste doit uniquement consulter les données.
-- Aucun droit d’écriture pour garantir l’intégrité des données.
GRANT SELECT ON nanoOrbit_db.* 
TO 'analyste_data'@'localhost';


-- =====================================================
-- OPERATEUR SAT (exploitation)
-- =====================================================

-- L’opérateur doit pouvoir consulter toutes les informations.
GRANT SELECT ON nanoOrbit_db.* 
TO 'operateur_sat'@'localhost';

-- Il gère les fenêtres de communication (ajout et mise à jour).
GRANT INSERT, UPDATE 
ON nanoOrbit_db.FENETRE_COM 
TO 'operateur_sat'@'localhost';

-- Il peut modifier uniquement le statut opérationnel des satellites,
-- sans toucher aux autres données techniques.
GRANT UPDATE (statut_operationnel) 
ON nanoOrbit_db.SATELLITE 
TO 'operateur_sat'@'localhost';


-- =====================================================
-- RESPONSABLE MISSIONS
-- =====================================================

-- Le responsable a besoin d’une vision globale pour planifier.
GRANT SELECT ON nanoOrbit_db.* 
TO 'resp_mission'@'localhost';

-- Il gère les missions (création et modification).
GRANT INSERT, UPDATE 
ON nanoOrbit_db.MISSION 
TO 'resp_mission'@'localhost';

-- Il gère aussi les participations (affectation des satellites).
GRANT INSERT, UPDATE 
ON nanoOrbit_db.PARTICIPATION 
TO 'resp_mission'@'localhost';

-- Aucun droit sur les tables techniques pour éviter toute erreur critique.


-- =====================================================
-- ADMIN TECHNIQUE
-- =====================================================

-- L’administrateur dispose de tous les droits DML.
-- Il peut lire, modifier, ajouter et supprimer des données.
GRANT SELECT, INSERT, UPDATE, DELETE 
ON nanoOrbit_db.* 
TO 'admin_nano'@'localhost';

-- Il peut créer des vues pour structurer et sécuriser l’accès aux données.
GRANT CREATE VIEW 
ON nanoOrbit_db.* 
TO 'admin_nano'@'localhost';


-- =====================================================
-- VERIFICATION INITIALE
-- =====================================================

-- Permet de contrôler que chaque utilisateur possède bien les droits attendus.
SHOW GRANTS FOR 'operateur_sat'@'localhost';
SHOW GRANTS FOR 'analyste_data'@'localhost';
SHOW GRANTS FOR 'resp_mission'@'localhost';
SHOW GRANTS FOR 'admin_nano'@'localhost';


-- =====================================================
-- MISSION 2 — INCIDENT SECURITE
-- =====================================================

-- Retrait du droit DELETE

-- Suite à un incident (suppression accidentelle),
-- on retire le droit DELETE à l’opérateur pour éviter toute suppression future.
REVOKE DELETE 
ON nanoOrbit_db.FENETRE_COM 
FROM 'operateur_sat'@'localhost';


-- Création stagiaire avec expiration 14 jours

-- stagiaire_obs :
-- Utilisateur temporaire (stagiaire).
-- Accès limité dans le temps pour des raisons de sécurité.
CREATE USER 'stagiaire_obs'@'localhost'
IDENTIFIED BY 'Stage123!'
PASSWORD EXPIRE INTERVAL 14 DAY;

-- Accès uniquement aux vues métier

-- Le stagiaire ne doit pas accéder aux tables brutes,
-- uniquement à des données filtrées et sécurisées via des vues.
GRANT SELECT 
ON nanoOrbit_db.VUE_SATELLITES_OPERATIONNELS 
TO 'stagiaire_obs'@'localhost';

GRANT SELECT 
ON nanoOrbit_db.VUE_BILAN_COMMUNICATIONS 
TO 'stagiaire_obs'@'localhost';


-- Vérification

-- Vérifie que l’opérateur n’a plus DELETE
-- et que le stagiaire a uniquement les droits prévus.
SHOW GRANTS FOR 'operateur_sat'@'localhost';
SHOW GRANTS FOR 'stagiaire_obs'@'localhost';


-- =====================================================
-- MISSION 3 — REORGANISATION
-- =====================================================

-- DevOps

-- devops_nano :
-- Ingénieur DevOps chargé du monitoring et de l’infrastructure.
-- Il ne doit pas modifier les données métier.
CREATE USER 'devops_nano'@'localhost' IDENTIFIED BY 'Devops123!';

-- Il peut consulter toutes les données pour superviser le système.
GRANT SELECT ON nanoOrbit_db.* 
TO 'devops_nano'@'localhost';

-- Il peut créer et supprimer des vues pour le monitoring,
-- sans accès direct à la modification des tables.
GRANT CREATE VIEW, DROP VIEW 
ON nanoOrbit_db.* 
TO 'devops_nano'@'localhost';


-- Resp mission change de périmètre

-- Le responsable missions ne gère plus les participations.
-- On retire donc ses droits d’écriture sur cette table.
REVOKE INSERT, UPDATE 
ON nanoOrbit_db.PARTICIPATION 
FROM 'resp_mission'@'localhost';


-- Admin peut déléguer SELECT

-- L’administrateur peut désormais transmettre ses droits SELECT.
-- Cela permet une gestion plus flexible des accès.
GRANT SELECT 
ON nanoOrbit_db.* 
TO 'admin_nano'@'localhost'
WITH GRANT OPTION;


-- Test délégation

-- Création d’un utilisateur test pour vérifier la délégation.
CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'Test123!';

-- admin_nano peut accorder SELECT à d’autres utilisateurs.
-- Ici, on vérifie qu’il peut transmettre ce droit sur une table spécifique.
GRANT SELECT ON nanoOrbit_db.SATELLITE 
TO 'test_user'@'localhost';
