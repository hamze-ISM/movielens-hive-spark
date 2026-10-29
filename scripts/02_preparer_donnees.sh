#!/bin/bash
# Partie 2 : copie des données Windows -> WSL, échantillon 1 %, chargement dans HDFS
# A lancer depuis la racine du projet : bash scripts/02_preparer_donnees.sh
set -e   # on s'arrête à la première erreur

SRC="/mnt/c/Users/User/Desktop/L3S5/Introduction au big data/TP Final/ml-latest"
HDFS_DIR=/user/ubuntu/movielens

# 1) copie dans WSL (plus rapide que de lire /mnt/c, pas d'espaces dans le chemin)
cp "$SRC/ratings.csv" "$SRC/movies.csv" "$SRC/README.txt" data/raw/

# 2) échantillon aléatoire de 1 % des notes (graine fixe = toujours le même échantillon)
awk -v seed=42 'BEGIN{srand(seed)} NR==1 || rand() < 0.01' data/raw/ratings.csv > data/sample/ratings_sample.csv
cp data/raw/movies.csv data/sample/movies.csv

# 3) chargement dans HDFS (un dossier par fichier, car une table Hive pointe vers un dossier)
hdfs dfs -mkdir -p $HDFS_DIR/{raw/ratings,raw/movies,sample/ratings,sample/movies,output/hive,output/spark}
hdfs dfs -put -f data/raw/ratings.csv          $HDFS_DIR/raw/ratings/
hdfs dfs -put -f data/raw/movies.csv           $HDFS_DIR/raw/movies/
hdfs dfs -put -f data/sample/ratings_sample.csv $HDFS_DIR/sample/ratings/
hdfs dfs -put -f data/sample/movies.csv        $HDFS_DIR/sample/movies/

echo "Données prêtes dans HDFS :"
hdfs dfs -ls -R -h $HDFS_DIR
