-- R01 — Catalogue des satellites
SELECT 
    s.id_satellite,
    s.nom_satellite,
    s.statut_operationnel,
    o.type_orbite
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
ORDER BY s.statut_operationnel, s.nom_satellite;

-- R02 — Instruments embarqués
SELECT 
    s.id_satellite,
    i.reference,
    i.type_instrument,
    i.modele,
    i.etat_fonctionnement
FROM SATELLITE s
JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
JOIN INSTRUMENT i ON e.reference = i.reference;

-- R03 — Historique des communications
SELECT 
    f.date_heure_debut,
    f.duree,
    s.nom_satellite,
    st.nom_station,
    f.statut
FROM FENETRE_COM f
JOIN SATELLITE s ON f.id_satellite = s.id_satellite
JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'TERMINEE'
ORDER BY f.date_heure_debut DESC;

-- R04 — Satellites par mission Arctic
SELECT 
    s.nom_satellite,
    p.role
FROM PARTICIPATION p
JOIN SATELLITE s ON p.id_satellite = s.id_satellite
JOIN MISSION m ON p.id_mission = m.id_mission
WHERE m.nom_mission LIKE '%Arctic%';

-- R05 — Stations disponibles
SELECT 
    nom_station,
    latitude,
    longitude,
    bande_frequence,
    debit_max
FROM STATION_SOL
WHERE statut = 'ACTIVE'
ORDER BY debit_max DESC;

-- R06 — Répartition de la flotte par orbite
SELECT 
    o.type_orbite,
    o.altitude,
    COUNT(s.id_satellite) AS nb_satellites,
    COUNT(CASE WHEN s.statut_operationnel = 'ACTIF' THEN 1 END) AS nb_actifs
FROM ORBITE o
JOIN SATELLITE s ON o.id_orbite = s.id_orbite
GROUP BY o.id_orbite, o.type_orbite, o.altitude
HAVING COUNT(s.id_satellite) > 0;

-- R07 — Bilan des instruments par satellite
SELECT 
    s.id_satellite,
    s.nom_satellite,
    COUNT(i.reference) AS nb_instruments,
    COUNT(CASE WHEN i.etat_fonctionnement = 'ACTIF' THEN 1 END) AS nb_actifs,
    SUM(i.consommation) AS conso_totale
FROM SATELLITE s
JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
JOIN INSTRUMENT i ON e.reference = i.reference
GROUP BY s.id_satellite, s.nom_satellite
ORDER BY nb_instruments DESC;

-- R08 — Volume de données par station
SELECT 
    st.nom_station,
    COUNT(f.id_fenetre) AS nb_fenetres,
    SUM(f.volume_donnees) AS volume_total,
    AVG(f.volume_donnees) AS volume_moyen
FROM STATION_SOL st
JOIN FENETRE_COM f ON st.code_station = f.code_station
WHERE f.statut = 'TERMINEE'
GROUP BY st.code_station, st.nom_station;

-- R09 — Satellites multi-missions
SELECT 
    s.id_satellite,
    s.nom_satellite,
    s.statut_operationnel,
    COUNT(p.id_mission) AS nb_missions
FROM SATELLITE s
JOIN PARTICIPATION p ON s.id_satellite = p.id_satellite
GROUP BY s.id_satellite, s.nom_satellite, s.statut_operationnel
HAVING COUNT(p.id_mission) > 1
ORDER BY nb_missions DESC;

-- R10 — Durée moyenne des passages par orbite
SELECT 
    o.type_orbite,
    AVG(f.duree) AS duree_moyenne,
    MAX(f.duree) AS duree_max,
    MIN(f.duree) AS duree_min
FROM ORBITE o
JOIN SATELLITE s ON o.id_orbite = s.id_orbite
JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
WHERE f.statut = 'TERMINEE'
GROUP BY o.type_orbite
HAVING COUNT(f.id_fenetre) >= 1;

-- R11 - Satellites sans mission (solution NOT IN)
SELECT 
    id_satellite,
    nom_satellite,
    statut_operationnel
FROM SATELLITE
WHERE id_satellite NOT IN (
    SELECT id_satellite FROM PARTICIPATION
);

-- R11 - Satellites sans mission (solution NOT EXISTS)
SELECT 
    s.id_satellite,
    s.nom_satellite,
    s.statut_operationnel
FROM SATELLITE s
WHERE NOT EXISTS (
    SELECT 1 
    FROM PARTICIPATION p
    WHERE p.id_satellite = s.id_satellite
);

-- R12 - Instruments nécessitant une attention
SELECT 
    s.nom_satellite,
    i.reference,
    i.type_instrument,
    i.etat_fonctionnement,
    s.statut_operationnel,
    CASE 
        WHEN i.etat_fonctionnement = 'DEGRADE' THEN 'Attention'
        WHEN i.etat_fonctionnement = 'INACTIF' AND s.statut_operationnel = 'ACTIF' THEN 'CRITIQUE'
        ELSE 'OK'
    END AS niveau_alerte
FROM SATELLITE s
JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
JOIN INSTRUMENT i ON e.reference = i.reference
WHERE i.etat_fonctionnement <> 'ACTIF';

-- R13 - Stations sans communication réalisée (LEFT JOIN)
SELECT 
    st.code_station,
    st.nom_station,
    st.statut,
    st.bande_frequence
FROM STATION_SOL st
LEFT JOIN FENETRE_COM f 
    ON st.code_station = f.code_station 
    AND f.statut = 'TERMINEE'
WHERE f.id_fenetre IS NULL;

-- Explication :
-- Une station peut être dans cette situation si elle est en maintenance,
-- récemment ajoutée ou n’a encore traité aucune communication (RG-G03).

-- R14 - Satellites les plus communicants
SELECT 
    s.id_satellite,
    s.nom_satellite,
    COUNT(f.id_fenetre) AS nb_fenetres,
    COUNT(DISTINCT f.code_station) AS nb_stations
FROM SATELLITE s
JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
WHERE s.statut_operationnel = 'ACTIF'
AND f.statut = 'TERMINEE'
GROUP BY s.id_satellite, s.nom_satellite
HAVING COUNT(DISTINCT f.code_station) >= 2
ORDER BY nb_fenetres DESC;

-- R15 - Analyse croisée missions / orbites
SELECT 
    m.id_mission,
    m.nom_mission,
    COUNT(DISTINCT s.id_satellite) AS nb_satellites,
    GROUP_CONCAT(DISTINCT o.type_orbite) AS types_orbites
FROM MISSION m
JOIN PARTICIPATION p ON m.id_mission = p.id_mission
JOIN SATELLITE s ON p.id_satellite = s.id_satellite
JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE m.statut = 'EN_COURS'
GROUP BY m.id_mission, m.nom_mission;

-- V01 - Création vue satellites opérationnels
CREATE OR REPLACE VIEW VUE_SATELLITES_OPERATIONNELS AS
SELECT 
    s.id_satellite,
    s.nom_satellite,
    s.format_cubesat,
    s.date_lancement,
    o.type_orbite,
    o.altitude,
    s.capacite_batterie
FROM SATELLITE s
JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE s.statut_operationnel = 'ACTIF';

-- V01 (a) Satellites opérationnels en SSO
SELECT *
FROM VUE_SATELLITES_OPERATIONNELS
WHERE type_orbite = 'SSO';

-- V01 (b) Âge moyen en jours
SELECT AVG(DATEDIFF(CURDATE(), date_lancement)) AS age_moyen_jours
FROM VUE_SATELLITES_OPERATIONNELS;



-- V02 - Création vue bilan communications
CREATE OR REPLACE VIEW VUE_BILAN_COMMUNICATIONS AS
SELECT 
    s.id_satellite,
    s.nom_satellite,
    COUNT(f.id_fenetre) AS nb_fenetres,
    SUM(f.volume_donnees) AS volume_total,
    AVG(f.volume_donnees) AS volume_moyen,
    MAX(f.date_heure_debut) AS derniere_comm,
    COUNT(DISTINCT f.code_station) AS nb_stations
FROM SATELLITE s
JOIN FENETRE_COM f ON s.id_satellite = f.id_satellite
WHERE f.statut = 'TERMINEE'
GROUP BY s.id_satellite, s.nom_satellite;

-- V02 (a) Satellite avec volume max
SELECT *
FROM VUE_BILAN_COMMUNICATIONS
ORDER BY volume_total DESC
LIMIT 1;

-- V02 (b) Satellites opérationnels sans communication
SELECT s.id_satellite, s.nom_satellite
FROM SATELLITE s
WHERE s.statut_operationnel = 'ACTIF'
AND s.id_satellite NOT IN (
    SELECT id_satellite FROM VUE_BILAN_COMMUNICATIONS
);



-- V03 - Création vue tableau de bord missions
CREATE OR REPLACE VIEW VUE_TABLEAU_DE_BORD_MISSIONS AS
SELECT 
    m.id_mission,
    m.nom_mission,
    m.zone_geographique,
    m.date_debut,
    COUNT(DISTINCT s.id_satellite) AS nb_satellites,
    COUNT(CASE WHEN s.statut_operationnel = 'ACTIF' THEN 1 END) AS nb_operationnels
FROM MISSION m
JOIN PARTICIPATION p ON m.id_mission = p.id_mission
JOIN SATELLITE s ON p.id_satellite = s.id_satellite
WHERE m.statut = 'EN_COURS'
GROUP BY m.id_mission, m.nom_mission, m.zone_geographique, m.date_debut;

-- V03 (a) Missions avec au moins 2 satellites
SELECT *
FROM VUE_TABLEAU_DE_BORD_MISSIONS
WHERE nb_satellites >= 2;

-- V03 (b) Missions avec tous les satellites opérationnels
SELECT *
FROM VUE_TABLEAU_DE_BORD_MISSIONS
WHERE nb_satellites = nb_operationnels;



-- V04 - Création vue alertes instruments
CREATE OR REPLACE VIEW VUE_ALERTES_INSTRUMENTS AS
SELECT 
    s.nom_satellite,
    s.statut_operationnel,
    i.reference,
    i.type_instrument,
    i.etat_fonctionnement,
    CASE 
        WHEN s.statut_operationnel = 'ACTIF' THEN 'CRITIQUE'
        ELSE 'SURVEILLANCE'
    END AS priorite
FROM SATELLITE s
JOIN EMBARQUEMENT e ON s.id_satellite = e.id_satellite
JOIN INSTRUMENT i ON e.reference = i.reference
WHERE i.etat_fonctionnement <> 'ACTIF';

-- V04 (a) Alertes critiques
SELECT *
FROM VUE_ALERTES_INSTRUMENTS
WHERE priorite = 'CRITIQUE';

-- V04 (b) Nombre d’alertes par type d’instrument
SELECT 
    type_instrument,
    COUNT(*) AS nb_alertes
FROM VUE_ALERTES_INSTRUMENTS
GROUP BY type_instrument;

