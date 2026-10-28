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
