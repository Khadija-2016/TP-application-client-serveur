# TP2 : Architectures 2-tiers et 3-tiers comparées

Cours Applications Client-Serveur et Web, Licence 2 Réseaux et Télécommunications, ESP / UCAD.
Enseignant : Dr Keba Gueye. Binôme : Khadija Koumé et Seynabou Diop.

Le TP déploie la même application de scolarité de deux façons : en **2-tiers** (un client lourd Python qui parle directement à MariaDB) puis en **3-tiers** (une application web PHP qui parle à MariaDB à la place du client). On compare ensuite les deux sur le déploiement, la cohérence des règles, le trafic réseau et la sécurité.

## En bref

- **Déploiement** : le 3-tiers ne demande aucune installation sur les postes (un navigateur), le 2-tiers demande Python, `pymysql` et le programme sur chaque poste.
- **Cohérence** : en 2-tiers, un poste non mis à jour donne une autre décision (ESP260011 : VALIDÉ sur Windows en v1.0, NON VALIDÉ sur VM2 en v1.1). En 3-tiers, un seul fichier à modifier et tout le monde est à jour.
- **Réseau** : classement de 20 030 étudiants : 2 407,3 Kio reçus par le client en 2-tiers, 1 317 octets en 3-tiers (environ 1 870 fois moins).
- **Sécurité** : en 3-tiers, le port 3306 de la base peut être fermé à tous sauf au serveur d’application. En 2-tiers, c’est impossible.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `README.md` | Ce document : réponses aux questions Q1 à Q16 |
| `rapport_TP2.pdf` | Compte rendu complet avec les captures d’écran |
| `client_lourd.py` | Application 2-tiers, version 1.1 |
| `app3tiers/` | Application 3-tiers (PHP), version 1.1 |
| `utilisateurs_tp2.sql` | Création du compte MariaDB de l’application 3-tiers |
| `volume.sql`, `volume_annuler.sql` | Ajout puis retrait des données de volume (partie 4) |

## Environnement

- VM1 (192.168.75.130) : serveur de données MariaDB, base `scolarite`.
- VM2 (192.168.75.131) : serveur d’application Apache et PHP.
- Poste Windows (192.168.75.1) : client lourd, puis navigateur.

L’énoncé était écrit pour VirtualBox (192.168.56.x). Nous avons travaillé sous VMware : les adresses ont été remplacées dans les trois fichiers qui en contiennent (`client_lourd.py`, `app3tiers/inc/config.php`, `utilisateurs_tp2.sql`).

## Comment tester

**2-tiers.** `pip install pymysql`, puis `python client_lourd.py`. Menu : 1 liste des étudiants, 2 relevé de notes, 3 classement.

**3-tiers.** Sur VM2, copier `app3tiers` dans `/var/www/html/scolarite`. Sur VM1, exécuter `sudo mariadb < utilisateurs_tp2.sql`. Puis ouvrir `http://192.168.75.131/scolarite/`.

Les mots de passe ne sont pas versionnés : dans `client_lourd.py`, `app3tiers/inc/config.php` et `utilisateurs_tp2.sql`, ils sont remplacés par `A_DEFINIR` et sont à renseigner avant de tester.

---

## Réponses

### Partie 1 : l’application en 2-tiers

**Q1. Où sont la présentation, la logique métier et l’accès aux données ?**

Dans `client_lourd.py` :

- Présentation : les `print` et `input` du menu et des affichages (lignes 51 à 54, 63, 69, 73, 89 à 93 et 96 à 113).
- Logique métier : le seuil de validation (ligne 29), le calcul de la moyenne pondérée (lignes 39 à 42), la décision VALIDÉ ou NON VALIDÉ (ligne 72), le tri du classement (lignes 85 à 88) et le décompte des admis (ligne 92).
- Accès aux données : les paramètres de connexion (lignes 22 à 26), `pymysql.connect` (lignes 33 à 36) et les requêtes `SELECT` (lignes 52, 58, 64 à 66 et 80 à 82).

Les trois couches sont dans le même fichier et s’exécutent toutes sur le poste client. Seules les données sont sur VM1.

**Q2. Que découvre un étudiant qui récupère `client_lourd.py` ?**

Le fichier contient en clair l’adresse du serveur, le port 3306, le nom de la base, le compte `etudiant` et son mot de passe. L’étudiant peut donc se connecter à MariaDB avec n’importe quel outil (mysql, DBeaver, un script) sans passer par l’application, donc sans ses règles de gestion, et faire tout ce que les droits du compte permettent.

**Q3. Qu’aurait-il fallu installer sur 300 postes ?**

Sur chaque poste : Python 3, la bibliothèque `pymysql` et le programme, avec l’adresse du serveur à reconfigurer au besoin. Chaque mise à jour oblige à repasser sur les 300 postes.

### Partie 2 : la même application en 3-tiers

**Q4. Mêmes résultats dans les deux architectures ?**

Oui. Pour ESP260001, la moyenne est de 10,75 (VALIDÉ) dans les deux cas, et le nombre d’admis est de 18 sur 30 dans les deux cas. C’est indispensable : avec la même application et les mêmes données, les différences observées ensuite ne peuvent venir que de l’architecture.

**Q5. Qu’a installé Windows pour la version 3-tiers ?**

Rien, un navigateur suffit. En 2-tiers, il fallait Python, `pymysql` et le programme sur chaque poste.

**Q6. Que renvoie la requête vers `config.php` ?**

Un code 200 avec un corps vide. Apache ne renvoie pas le fichier : il le fait exécuter par PHP et ne transmet que ce qu’il affiche. `config.php` ne contient que des constantes et n’affiche rien, donc le mot de passe reste côté serveur et n’est jamais envoyé au navigateur.

**Q7. Combien de comptes MariaDB ?**

En 3-tiers, un seul : `app_scolarite`, avec le droit `SELECT` uniquement, utilisable seulement depuis VM2, quel que soit le nombre d’utilisateurs. En 2-tiers, un compte par utilisateur, ou un compte partagé dont le mot de passe est dans le programme de chaque poste.

**Q8. Que contient le code source de la page (Ctrl+U) ?**

Uniquement du HTML : aucune requête SQL, aucune règle de calcul, ni identifiant, ni mot de passe, ni adresse de la base. Le navigateur reçoit le résultat déjà calculé par le serveur.

### Partie 3 : faire évoluer une règle métier

Règle de la version 1.1 : une note inférieure à 8 dans un EC empêche la validation, quelle que soit la moyenne.

**Q9. Résultats en 2-tiers pour ESP260011**

Windows (resté en v1.0) déclare l’étudiant VALIDÉ (moyenne 12,55). VM2 (v1.1) le déclare NON VALIDÉ, à cause de sa note de 7,50 en Mathématiques discrètes. Le nombre d’admis diffère aussi : 18 sur 30 sur Windows, 16 sur 30 sur VM2.

Un même étudiant a donc deux décisions selon le poste utilisé. Pour une scolarité, cela veut dire des listes d’admis contradictoires, des contestations et des erreurs de délibération.

**Q10. Combien de fichiers, de machines, d’utilisateurs concernés en 3-tiers ?**

Un seul fichier (`metier.php`) sur une seule machine (VM2). Tous les utilisateurs en profitent immédiatement, dès le rechargement de la page, qui affiche alors « version 1.1 ». Rien à installer sur leurs postes.

**Q11. Où a-t-on modifié le code ?**

En 3-tiers, dans `metier.php`, côté serveur : la décision dans `releve()` (en PHP) et la requête du bilan dans `classement()` (en SQL, avec `MIN(n.valeur)`). En 2-tiers, dans `client_lourd.py` : la décision dans `releve()` et le décompte des admis dans `classement()`, donc sur chaque poste.

### Partie 4 : volume de données et réseau

Après ajout de 20 000 étudiants et 120 000 notes :

| Mesure | 2-tiers | 3-tiers |
|---|---|---|
| Données reçues par le poste client | 120 180 lignes, 2 407,3 Kio | 1 317 octets |
| Temps du classement | 810 ms | 840 à 915 ms (deux mesures) |
| Machine qui calcule | Poste client | Serveur (VM2 et MariaDB) |

**Q12. D’où vient l’écart, et que deviendrait-il en réseau lent ?**

En 2-tiers, le client rapatrie toutes les notes puis calcule moyennes, tri et admis lui-même. En 3-tiers, le serveur calcule et n’envoie que le top 10 et le bilan dans une petite page HTML. Le volume est environ 1 870 fois plus grand en 2-tiers.

Les temps sont voisins ici parce que le réseau VMware est très rapide. Avec 300 postes sur une liaison à 10 Mbit/s (environ 1 220 Kio/s) :

- en 2-tiers, 2 407,3 Kio par poste, soit environ 705 Mio au total : près de 2 s par poste, et environ 10 minutes si tous lancent le classement en même temps ;
- en 3-tiers, 1 317 octets par poste, soit environ 0,3 s pour les 300 postes.

Sur une connexion mobile, le 2-tiers serait lent et coûteux en données.

Remarque sur le nombre d’admis : les deux mesures ne se comparent pas, car le client Windows est resté en v1.0 (9 407 admis sur 20 030) alors que le serveur est en v1.1 (16 admis sur 20 030). L’écart vient de la règle appliquée, pas de l’architecture. C’est exactement le problème de cohérence de la question 9.

**Q13. Que mesure `Bytes_sent` ?**

Le programme lit `SHOW SESSION STATUS LIKE 'Bytes_sent'` : le nombre d’octets envoyés par le serveur sur cette connexion. La différence avant et après la requête donne exactement le volume renvoyé. La mesure est honnête car elle vient du serveur, elle est propre à la connexion du client et elle compte les octets réellement émis, pas une estimation.

### Partie 5 : sécurité

Sur VM1, le port 3306 est ouvert uniquement depuis VM2 :

```
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow from 192.168.75.131 to any port 3306 proto tcp
sudo ufw deny 3306/tcp
sudo ufw enable
```

**Q14. Que se passe-t-il pour chaque architecture ?**

En 2-tiers, le client lourd sur Windows ne peut plus se connecter (erreur « timed out »). En 3-tiers, l’application web continue de fonctionner, car c’est VM2, autorisée, qui parle à MariaDB. En 2-tiers, on ne peut pas appliquer cette protection : chaque poste client se connecte directement à la base, donc le port 3306 doit rester ouvert à tous.

**Q15. Deux autres risques du client lourd**

1. Le mot de passe de la base est distribué sur chaque poste. En 3-tiers, il reste sur le serveur d’application.
2. Le code et les règles métier sont modifiables ou contournables par l’utilisateur, qui peut garder une version obsolète ou truquée. En 3-tiers, la logique reste sur le serveur, hors de sa portée.

### Synthèse

| Critère | 2-tiers | 3-tiers |
|---|---|---|
| Logiciel sur chaque poste | Python, `pymysql`, programme | Navigateur seul |
| Déploiement d’une nouvelle règle | Mise à jour de chaque poste | Un fichier sur un serveur |
| Cohérence entre utilisateurs | Risque de versions différentes | Une seule version |
| Trafic réseau côté client | Élevé (lignes brutes) | Faible (page HTML) |
| Exposition de la base et des mots de passe | Forte : port 3306 ouvert, mot de passe sur les postes | Réduite : seul VM2 accède à la base |
| Charge des serveurs | Légère, mais lourde pour clients et réseau | Plus forte sur le serveur d’application |
| Simplicité de développement | Un seul programme | Plus complexe (couches séparées, deux serveurs) |

**Q16. Quand le 2-tiers est-il acceptable, et pourquoi le 3-tiers pour la scolarité ?**

Le 2-tiers convient avec peu d’utilisateurs et de postes maîtrisés par la même personne, sur un réseau local de confiance, avec des utilisateurs de confiance (ou des droits très limités), peu d’évolutions des règles et des volumes raisonnables : caisse de boutique, poste de saisie d’un laboratoire, outil d’administration.

Pour une scolarité utilisée par toute l’université, le 3-tiers s’impose : aucune installation sur les postes, une règle unique appliquée à tous immédiatement, une base et des mots de passe inaccessibles aux utilisateurs (port 3306 fermé sauf VM2), un trafic réseau réduit et la possibilité d’ajouter des serveurs d’application pour absorber la charge.

## Conclusion

Le choix de l’architecture a des conséquences concrètes. Le 2-tiers est simple à développer mais difficile à déployer, à tenir à jour et à protéger. Le 3-tiers demande plus de conception, mais il centralise la logique métier, garantit des résultats cohérents, réduit le trafic côté client et permet de fermer l’accès direct à la base.
