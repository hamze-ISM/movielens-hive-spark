# Journal de bord du projet

## Partie 0 : Vérification de l'environnement

| Élément | Valeur / choix |
|---|---|
| Système | Windows + WSL 2, Ubuntu 24.04, utilisateur `ubuntu` |
| Mémoire WSL | 5 Go + 4 Go de swap (`.wslconfig`), 8 cœurs |
| Versions | Java 11, Hadoop 3.3.6, Hive 3.1.3, PySpark 3.5.9, Python 3.12 |
| Ajouts Python | pandas, matplotlib, notebook, ipykernel (`pip install --user`) |
| HDFS | `hdfs://localhost:8020`, réplication 1 |
| Hive | moteur MapReduce en **mode local**, metastore Derby, mémoire portée à 1,5 Go (`hive-env.sh`) |
| YARN | non utilisé : trop gourmand pour 4,8 Go de RAM dans WSL |
| Spark | mode local, réglages écrits dans le code |

- Problème rencontré : 5 conteneurs Docker (SonarQube, Jenkins, Grafana, Prometheus, node-exporter)
  occupaient environ 1,5 Go → arrêtés avec `docker stop` (2,7 Go → 1,2 Go utilisés).
- Routine de début de séance : `start-dfs.sh` puis `hdfs dfsadmin -safemode wait` puis `jps`.
- Détail du diagnostic : `docs/verif_env.txt`.

## Partie 1 : Arborescence et dépôt Git

- Projet placé dans WSL (`~/movielens-hive-spark`) et non sur le Bureau Windows :
  plus rapide, pas d'espaces dans le chemin, pas de OneDrive.
- HDFS : `/user/ubuntu/movielens/` avec `raw/`, `sample/`, `output/` ;
  un dossier par fichier, car une table Hive pointe vers un dossier.
- `.gitignore` : données et logs exclus, seuls les petits CSV de `results/` sont versionnés.
- Dépôt public : https://github.com/hamze-ISM/movielens-hive-spark

## Partie 2 : Données Windows -> WSL -> HDFS

- Source : `C:\Users\User\Desktop\L3S5\Introduction au big data\TP Final\ml-latest`,
  vue depuis Ubuntu sous `/mnt/c/Users/User/Desktop/...` (chemin entre guillemets à cause des espaces).
- Fichiers utilisés : `ratings.csv` et `movies.csv` uniquement (+ `README.txt` pour la documentation).
- Copie dans `data/raw/` : tailles identiques au octet près (933 898 879 et 4 192 335 octets).

| Fichier | Lignes (en-tête compris) | Contenu | Taille |
|---|---|---|---|
| ratings.csv | 33 832 163 | 33 832 162 notes (userId, movieId, rating, timestamp) | 891 Mo |
| movies.csv | 86 538 | 86 537 films (movieId, title, genres) | 4 Mo |

- Encodage : ratings en ASCII, movies en UTF-8, fins de ligne Linux (pas de CRLF).
- 7 540 titres contiennent une virgule et sont entre guillemets
  (ex. `"American President, The (1995)"`) -> il faut un lecteur CSV qui gère les guillemets.
- Échantillon de test : 1 % des notes tirées au hasard (awk, graine 42) -> 338 648 notes,
  `data/sample/ratings_sample.csv` (8,9 Mo). Sert uniquement à tester le code.
- HDFS : `ratings.csv` -> 7 blocs de ~128 Mo, réplication 1, statut HEALTHY ;
  même nombre de lignes dans HDFS qu'en local (33 832 163).
- Commandes regroupées dans `scripts/02_preparer_donnees.sh`.

## Partie 3 : Qualité des données (Véracité)

- Base `movielens` (jeu complet) et `movielens_sample` (échantillon), créées par le même script
  `hive/01_creer_tables.hql` avec `--hivevar db=... --hivevar dir=...`.
- Tables externes : `ratings_raw` (CSV simple, colonnes typées, en-tête sauté) et `movies_raw`
  (OpenCSVSerde pour les titres entre guillemets, colonnes en texte).
- Vues : `movies` (movieId converti en entier) et `ratings_dates` (timestamp -> date avec `from_unixtime`).
- Problème rencontré : `WITH SERDEPROPERTIES (... 'quoteChar'='"')` -> `ParseException`, car le client Hive
  prend le guillemet double seul pour le début d'un texte et découpe mal le script.
  Solution : ligne supprimée, la virgule et le guillemet double sont déjà les réglages par défaut d'OpenCSVSerde.

| Contrôle (jeu complet) | Résultat |
|---|---|
| Notes | 33 832 162 |
| Valeurs manquantes ou illisibles (4 colonnes) | 0 |
| Notes invalides (hors 0,5-5 ou non multiples de 0,5) | 0 |
| Doublons (même utilisateur, même film) | 0 |
| Notes sur un film absent de movies.csv | 0 |
| Films / identifiants distincts / illisibles | 86 537 / 86 537 / 0 |
| Utilisateurs | 330 975 |
| Films ayant au moins une note | 83 239 (3 298 films sans aucune note) |
| Période | du 1995-01-09 au 2023-07-20 (seulement 4 notes en 1995) |
| Note la plus fréquente | 4,0 (8,8 millions) |

- Décision : aucune correction nécessaire, le top 10 lira directement `ratings_raw` et `movies`.
- Durées Hive (mode local) : contrôles 1-3 = 18 min 17 s (COUNT DISTINCT + doublons sur 33 M de paires),
  contrôles 4-6 = 2 min 27 s.
- Résultats bruts : `results/qualite_notes_*.txt` et `results/qualite_films_dates_*.txt`.
