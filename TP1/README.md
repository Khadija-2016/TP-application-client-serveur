# TP1 — Le modèle client-serveur

**Cours :** ACSW, DUT2 Réseaux et Télécommunications, ESP/UCAD — Dr Keba GUEYE
**Binôme :** Khadija Koumé et Seynabou Diop

Rapport complet avec les captures : [rapport_TP1.pdf](rapport_TP1.pdf)

**Environnement :** VMware. Hôte Windows = 192.168.75.1, VM1 (serveur) = 192.168.75.130, VM2 (client) = 192.168.75.131. Ces adresses remplacent celles de l'énoncé (192.168.56.x).

## Réponses

**Q1.** 30 étudiants, 6 EC et 180 notes (6 par étudiant), 2 filières. Quatre tables : `filiere`, `etudiant`, `ec`, `note`. La table `note` relie un étudiant à un EC par deux clés étrangères, et la contrainte UNIQUE (`matricule`, `ec`) interdit deux notes pour le même étudiant dans le même EC.

**Q2.** Non, ce sont deux programmes distincts. Le serveur `mariadbd` (PID 1483, utilisateur `mysql`) tourne en tâche de fond, sans terminal. Le client `mariadb` (PID 12284) est lancé par nous, rattaché à un terminal, et disparaît quand on quitte la session.

**Q3.** Le code 10061 signifie « connexion refusée ». VM1 était joignable (ping OK) et MariaDB fonctionnait, mais il n'écoutait que sur 127.0.0.1, pas sur 192.168.75.130. Le pare-feu n'est pas en cause (`ufw` inactif).

**Q4.** 127.0.0.1 est l'adresse de bouclage : seules les connexions de la machine elle-même sont acceptées. 0.0.0.0 veut dire « toutes les adresses de la machine » : le réseau peut donc se connecter. Ubuntu choisit 127.0.0.1 par prudence, pour ne pas exposer une base au réseau sans décision de l'administrateur.

**Q5.** `USER()` = `etudiant@192.168.75.1` : l'identité annoncée par le client. `CURRENT_USER()` = `etudiant@192.168.75.%` : le compte retenu par le serveur, le plus précis qui correspond. Ce sont les droits de `CURRENT_USER()` qui s'appliquent.

**Q6.** Aucun compte ne le permet : `root` n'existe que pour `localhost`. Notre essai donne `Access denied for user 'root'@'192.168.75.1'`. Cette fois, la connexion réseau a abouti et c'est le serveur qui refuse l'identité. Le compte le plus puissant n'est ainsi pas attaquable depuis le réseau.

**Q7.** Le PROCESSLIST montre deux connexions qui exécutent `SELECT SLEEP(60)` : `etudiant` depuis 192.168.75.1:57485 et `secretariat` depuis 192.168.75.131:60882. Ces ports sources sont choisis par le système de chaque client (ports éphémères) et diffèrent de 3306, le port du serveur. Une connexion TCP est identifiée par quatre valeurs (IP et port source, IP et port destination), ce qui permet au serveur de distinguer les clients.

**Q8.** `etudiant` : l'UPDATE est refusé (ERROR 1142). `secretariat` : l'UPDATE réussit, le DELETE est refusé (il n'a que INSERT et UPDATE sur `note`). Les droits sont stockés et vérifiés par le serveur, jamais par le client : un client ne peut pas se donner des droits en modifiant son logiciel.

**Q9.** Oui, Windows lit tout de suite la valeur 12 modifiée depuis VM2. Il n'existe qu'une seule copie des données, chez le serveur. La valeur d'origine (9,25) a été remise à la fin.

**Q10.** Les lignes `>` sont la requête du client, les lignes `<` la réponse du serveur. Requête : `GET / HTTP/1.1` (méthode, chemin, version) avec les en-têtes `Host`, `User-Agent`, `Accept`. Réponse : `HTTP/1.1 200 OK` (version, code, libellé), des en-têtes (`Server`, `Content-Type`, `Content-Length: 1146`), une ligne vide, puis le HTML.

**Q11.** Apache note l'IP du client, l'heure, la requête, le code de réponse, la taille et le User-Agent. Notre `access.log` :

- 192.168.75.1 (Windows) : `GET /` → 200, navigateur Edge
- 192.168.75.1 (Windows) : `GET /favicon.ico` → 404, demandé automatiquement par le navigateur
- 192.168.75.130 (VM1) : `GET /` → 200, premier `curl` lancé par erreur depuis VM1
- 192.168.75.131 (VM2) : `GET /` → 200, `curl/8.5.0`

Le journal contient aussi un code 408 : le navigateur avait ouvert une connexion sans envoyer de requête.

**Q12.** Par le numéro de port : `apache2` écoute sur le port 80, `mariadbd` sur le 3306. L'adresse IP désigne la machine, le port désigne le service. Le client doit connaître l'adresse et le port du serveur ; le serveur n'a pas besoin de connaître le client à l'avance.

**Q13.** MariaDB garde la connexion ouverte pendant toute la session : pas de réauthentification à chaque requête, mais des ressources occupées même sans activité. HTTP traite chaque requête de façon indépendante : le serveur reste léger, mais il ne garde aucun souvenir. Les cookies et les sessions permettent à un site de reconnaître l'utilisateur.

**Q14.** Les deux clients échouent : HeidiSQL (erreur 2002, code 10061) et VM2 (ERROR 2002, code 115). Le message est le même qu'en Q3, mais la cause est différente : plus aucun programme n'écoute sur le port 3306. C'est un point unique de défaillance. Apache, lui, continue de répondre sur le port 80.

**Q15.** Visibles en clair dans la capture : le nom du compte, le texte de la requête, les données de la réponse (le nom SECK et ses notes) et les requêtes automatiques de HeidiSQL (`SHOW CREATE TABLE`). Le mot de passe n'apparaît pas (recherche = 0 résultat) : MariaDB envoie une valeur calculée à partir d'un défi du serveur. Mais tout le reste est lisible par une machine placée sur le trafic. Pour se protéger : TLS, tunnel SSH ou VPN.

**Q16.** Le serveur (`mariadbd`, `apache2`) tourne en permanence sur une adresse et un port connus. Les clients (HeidiSQL, `mariadb`, navigateur, `curl`) ouvrent la connexion, envoient une requête et attendent la réponse. Le serveur détient les données et vérifie les droits ; les clients ne communiquent jamais entre eux.

- Avantages : données centralisées donc cohérentes, droits et sécurité gérés à un seul endroit.
- Inconvénients : le serveur est un point unique de défaillance, et le trafic circule en clair s'il n'est pas chiffré.

## Synthèse

| | MariaDB | Apache (HTTP) |
|---|---|---|
| Serveur | VM1, port 3306 | VM1, port 80 |
| Clients | HeidiSQL, `mariadb` | Edge, `curl` |
| Initiative | Le client | Le client |
| Connexion | Persistante (toute la session) | Courte (une requête, une réponse) |
| Droits | Vérifiés par le serveur (comptes) | Pas d'authentification sur notre page |
| Si le serveur s'arrête | Tous les clients perdent le service | Idem (non testé) |
