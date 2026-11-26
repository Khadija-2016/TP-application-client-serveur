-- =====================================================================
-- utilisateurs_tp2.sql — Compte de l'APPLICATION 3-tiers (TP2)
-- À exécuter sur VM1 :  sudo mariadb < utilisateurs_tp2.sql
--
-- Le compte n'est utilisable QUE depuis le serveur d'application (VM2).
-- Les postes clients n'ont plus besoin d'aucun compte de base de données.
-- =====================================================================
DROP USER IF EXISTS 'app_scolarite'@'192.168.75.131';
CREATE USER 'app_scolarite'@'192.168.75.131' IDENTIFIED BY 'A_DEFINIR';
GRANT SELECT ON scolarite.* TO 'app_scolarite'@'192.168.75.131';
FLUSH PRIVILEGES;
