-- =========================
-- QUESTIONS DE CONCEPTION
-- =========================

-- Q1 — Pourquoi ne peut-on pas créer SATELLITE avant ORBITE ? Quelle règle de gestion cela traduit-il ?
-- On ne peut pas créer SATELLITE avant ORBITE car SATELLITE contient une clé étrangère (id_orbite) qui référence la table ORBITE.
-- Donc la table référencée doit exister avant sinon erreur de contrainte

-- Q2 — Le champ format_cubesat dans SATELLITE : quel type SQL choisissez-vous et pourquoi ? (les valeurs possibles sont
-- 1U, 3U, 6U, 12U)
-- ENUM('1U','3U','6U','12U')
-- Parceque:
-- valeurs fermées et connues à l’avance
-- évite les erreurs (2U, 10U, etc.)
-- plus lisible qu’un INT

-- Q3 — Comment implémentez-vous la contrainte RG-I03 (un instrument ne peut pas être embarqué sur deux satellites
-- simultanément) ? Cette contrainte est-elle directement exprimable en SQL au niveau DDL ?
-- Cette contrainte n’est pas entièrement exprimable en DDL, elle nécessite un trigger

-- Q4 — La règle RG-S06 (satellite désorbité : plus de fenêtre ni de mission) peut-elle être vérifiée au niveau DDL ? Quelle
-- solution proposez-vous ?
-- Cette règle ne peut pas être entièrement implémentée en DDL car elle dépend d’un état métier. Elle doit être gérée via des triggers ou au niveau applicatif.

-- =========================
-- RESET (optionnel)
-- =========================
DROP DATABASE IF EXISTS nanoOrbit_db;

CREATE DATABASE nanoOrbit_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE nanoOrbit_db;

-- =========================
-- 1. ORBITE
-- =========================
CREATE TABLE ORBITE (
    id_orbite INT AUTO_INCREMENT,
    type_orbite ENUM('LEO','SSO','MEO','GEO') NOT NULL,
    altitude INT NOT NULL,
    inclinaison DECIMAL(5,2) NOT NULL,
    periode_orbitale DECIMAL(6,2) NOT NULL,
    excentricite DECIMAL(6,6) NOT NULL,
    zone_couverture VARCHAR(100) NOT NULL,
    PRIMARY KEY(id_orbite),
    UNIQUE (altitude, inclinaison)
) ENGINE=InnoDB;

-- =========================
-- 2. INSTRUMENT
-- =========================
CREATE TABLE INSTRUMENT (
    reference VARCHAR(50),
    type_instrument ENUM('CAMERA','SPECTROMETRE','AIS') NOT NULL,
    modele VARCHAR(100) NOT NULL,
    resolution DECIMAL(10,2) NULL,
    consommation DECIMAL(10,2) NOT NULL,
    masse DECIMAL(10,2) NOT NULL,
    date_integration DATE NOT NULL,
    etat_fonctionnement ENUM('ACTIF','INACTIF','DEGRADE') NOT NULL,
    PRIMARY KEY(reference)
) ENGINE=InnoDB;

-- =========================
-- 3. STATION_SOL
-- =========================
CREATE TABLE STATION_SOL (
    code_station VARCHAR(50),
    nom_station VARCHAR(100) NOT NULL,
    latitude DECIMAL(8,5) NOT NULL,
    longitude DECIMAL(8,5) NOT NULL,
    diametre_antenne DECIMAL(5,2) NOT NULL,
    bande_frequence ENUM('S','X','Ka','Ku') NOT NULL,
    debit_max DECIMAL(10,2) NOT NULL,
    statut ENUM('ACTIVE','INACTIVE','MAINTENANCE') NOT NULL,
    PRIMARY KEY(code_station)
) ENGINE=InnoDB;

-- =========================
-- 4. MISSION
-- =========================
CREATE TABLE MISSION (
    id_mission VARCHAR(50),
    nom_mission VARCHAR(100) NOT NULL,
    objectif TEXT NOT NULL,
    zone_geographique VARCHAR(100) NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NULL,
    statut ENUM('EN_COURS','TERMINEE','PLANIFIEE') NOT NULL,
    PRIMARY KEY(id_mission)
) ENGINE=InnoDB;

-- =========================
-- 5. SATELLITE
-- =========================
CREATE TABLE SATELLITE (
    id_satellite VARCHAR(50),
    nom_satellite VARCHAR(100) NOT NULL,
    date_lancement DATE NOT NULL,
    masse DECIMAL(10,2) NOT NULL,
    format_cubesat ENUM('1U','3U','6U','12U') NOT NULL,
    statut_operationnel ENUM('ACTIF','INACTIF','HS') NOT NULL,
    duree_vie_prevue INT NOT NULL,
    capacite_batterie DECIMAL(10,2) NOT NULL,
    id_orbite INT NOT NULL,
    PRIMARY KEY(id_satellite),
    FOREIGN KEY (id_orbite) REFERENCES ORBITE(id_orbite) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================
-- 6. PARTICIPATION
-- =========================
CREATE TABLE PARTICIPATION (
    id_satellite VARCHAR(50),
    id_mission VARCHAR(50),
    role VARCHAR(100) NOT NULL,
    PRIMARY KEY(id_satellite, id_mission),
    FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite) ON DELETE RESTRICT,
    FOREIGN KEY (id_mission) REFERENCES MISSION(id_mission) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================
-- 7. EMBARQUEMENT
-- =========================
CREATE TABLE EMBARQUEMENT (
    id_satellite VARCHAR(50),
    reference VARCHAR(50),
    date_integration DATE NOT NULL,
    PRIMARY KEY(id_satellite, reference),
    FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite) ON DELETE RESTRICT,
    FOREIGN KEY (reference) REFERENCES INSTRUMENT(reference) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================
-- 8. FENETRE_COM
-- =========================
CREATE TABLE FENETRE_COM (
    id_fenetre INT AUTO_INCREMENT,
    date_heure_debut DATETIME NOT NULL,
    duree INT NOT NULL,
    elevation_max DECIMAL(5,2) NOT NULL,
    volume_donnees DECIMAL(10,2) NULL,
    statut ENUM('PLANIFIEE','TERMINEE') NOT NULL,
    id_satellite VARCHAR(50) NOT NULL,
    code_station VARCHAR(50) NOT NULL,
    PRIMARY KEY(id_fenetre),
    FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite) ON DELETE RESTRICT,
    FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station) ON DELETE RESTRICT,
    CHECK (duree BETWEEN 1 AND 900)
) ENGINE=InnoDB;

-- =========================
-- INSERT DATA
-- =========================

-- ORBITE
INSERT INTO ORBITE VALUES
(1,'SSO',550,97.40,95.70,0.001000,'Zones polaires / Arctique'),
(2,'LEO',400,51.60,92.65,0.000300,'Ceinture tropicale'),
(3,'SSO',600,97.80,96.70,0.000800,'Amazonie / Afrique centrale');

-- INSTRUMENT
INSERT INTO INSTRUMENT VALUES
('CAM-HR-01','CAMERA','PocketQube-CAM v2',5.0,3.2,0.45,'2023-02-01','ACTIF'),
('IR-MID-01','SPECTROMETRE','ThermoSat IRv3',30.0,2.8,0.38,'2023-02-01','ACTIF'),
('AIS-01','AIS','MarineTrack-Nano',NULL,1.5,0.22,'2023-02-10','ACTIF'),
('CAM-HR-02','CAMERA','PocketQube-CAM v3',3.5,4.0,0.50,'2024-01-05','ACTIF');

-- STATION
INSERT INTO STATION_SOL VALUES
('GS-TLS-01','Toulouse-CNES',43.6050,1.4440,3.7,'S',100.0,'ACTIVE'),
('GS-KIR-01','Kiruna-SSC',67.8560,20.2280,5.4,'X',300.0,'ACTIVE'),
('GS-SGP-01','Singapore-SATEC',1.3521,103.8198,2.8,'S',80.0,'MAINTENANCE');

-- MISSION
INSERT INTO MISSION VALUES
('MSN-AMA-2023','ForestWatch','Surveillance déforestation','Amérique du Sud','2023-04-01','2025-03-31','EN_COURS'),
('MSN-ARC-2023','ArcticIce Monitor','Surveillance glace','Arctique','2023-04-01',NULL,'EN_COURS'),
('MSN-AIS-2024','SeaTrack Global','Suivi maritime','Océans','2024-02-01','2024-12-31','TERMINEE');

-- SATELLITE
INSERT INTO SATELLITE VALUES
('SAT-001','NanoOrbitAlpha','2023-03-12',4.5,'3U','ACTIF',36,60.0,1),
('SAT-002','NanoOrbitBeta','2023-03-12',4.5,'3U','ACTIF',36,60.0,1),
('SAT-003','NanoOrbitGamma','2023-09-05',8.2,'6U','INACTIF',48,110.0,2),
('SAT-004','NanoOrbitDelta','2024-01-20',4.8,'3U','ACTIF',36,65.0,3),
('SAT-005','NanoOrbitEpsilon','2022-06-15',4.5,'3U','HS',24,55.0,1);

-- PARTICIPATION
INSERT INTO PARTICIPATION VALUES
('SAT-001','MSN-AMA-2023','Satellite primaire'),
('SAT-002','MSN-AMA-2023','Backup'),
('SAT-003','MSN-ARC-2023','Primaire'),
('SAT-001','MSN-ARC-2023','Calibration'),
('SAT-004','MSN-AIS-2024','Primaire'),
('SAT-002','MSN-AIS-2024','Backup');

-- EMBARQUEMENT
INSERT INTO EMBARQUEMENT VALUES
('SAT-001','CAM-HR-01','2023-02-01'),
('SAT-001','IR-MID-01','2023-02-01'),
('SAT-002','CAM-HR-01','2023-02-10'),
('SAT-002','AIS-01','2023-02-10'),
('SAT-003','IR-MID-01','2023-08-01'),
('SAT-004','CAM-HR-02','2024-01-05'),
('SAT-004','AIS-01','2024-01-05');

-- FENETRE
INSERT INTO FENETRE_COM VALUES
(1,'2024-03-15 14:32:00',420,68.4,1250.0,'TERMINEE','SAT-001','GS-TLS-01'),
(2,'2024-03-15 16:08:00',380,52.1,890.0,'TERMINEE','SAT-002','GS-KIR-01'),
(3,'2024-03-16 08:15:00',510,74.2,NULL,'PLANIFIEE','SAT-003','GS-KIR-01'),
(4,'2024-03-16 09:00:00',300,45.0,NULL,'PLANIFIEE','SAT-004','GS-TLS-01'),
(5,'2024-03-15 22:44:00',280,38.7,620.0,'TERMINEE','SAT-001','GS-KIR-01');

SELECT s.nom_satellite, o.type_orbite
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE s.statut_operationnel = 'ACTIF';

SELECT i.reference, i.modele, i.etat_fonctionnement
FROM EMBARQUEMENT e
JOIN INSTRUMENT i ON e.reference = i.reference
WHERE e.id_satellite = 'SAT-001';

SELECT f.id_fenetre, s.nom_satellite, st.nom_station
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'TERMINEE';

SELECT s.nom_satellite, p.role
FROM PARTICIPATION p
JOIN SATELLITE s ON p.id_satellite = s.id_satellite
WHERE p.id_mission = 'MSN-ARC-2023';

SELECT e.id_satellite, COUNT(*) AS nb_instruments
FROM EMBARQUEMENT e
GROUP BY e.id_satellite
ORDER BY nb_instruments DESC;

-- =========================
-- RÉPONSES AUX REQUÊTES SELECT
-- =========================

-- 1. Satellites actifs et leur type d'orbite
-- +----------------+-------------+
-- | nom_satellite  | type_orbite |
-- +----------------+-------------+
-- | NanoOrbitAlpha | SSO         |
-- | NanoOrbitBeta  | SSO         |
-- | NanoOrbitDelta | SSO         |
-- +----------------+-------------+

-- 2. Instruments embarqués sur SAT-001
-- +-----------+-------------------+---------------------+
-- | reference | modele            | etat_fonctionnement |
-- +-----------+-------------------+---------------------+
-- | CAM-HR-01 | PocketQube-CAM v2 | ACTIF               |
-- | IR-MID-01 | ThermoSat IRv3    | ACTIF               |
-- +-----------+-------------------+---------------------+

-- 3. Fenêtres de communication terminées
-- +------------+----------------+---------------+
-- | id_fenetre | nom_satellite  | nom_station   |
-- +------------+----------------+---------------+
-- |          2 | NanoOrbitBeta  | Kiruna-SSC    |
-- |          5 | NanoOrbitAlpha | Kiruna-SSC    |
-- |          1 | NanoOrbitAlpha | Toulouse-CNES |
-- +------------+----------------+---------------+

-- 4. Satellites et rôles pour la mission MSN-ARC-2023
-- +----------------+-------------+
-- | nom_satellite  | role        |
-- +----------------+-------------+
-- | NanoOrbitAlpha | Calibration |
-- | NanoOrbitGamma | Primaire    |
-- +----------------+-------------+

-- 5. Nombre d'instruments par satellite
-- +--------------+----------------+
-- | id_satellite | nb_instruments |
-- +--------------+----------------+
-- | SAT-001      |              2 |
-- | SAT-004      |              2 |
-- | SAT-002      |              2 |
-- | SAT-003      |              1 |
-- +--------------+----------------+
