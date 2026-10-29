#!/bin/bash
# Partie 6 : lance le top 10 Spark plusieurs fois sur le jeu complet et note la durée de chaque exécution
# Utilisation (depuis la racine du projet) : bash scripts/06_chrono_spark.sh 3
set -e
N=${1:-3}
echo "outil,execution,duree_s" > results/temps_spark.csv

for i in $(seq 1 $N); do
  debut=$(date +%s.%N)
  spark-submit --master "local[*]" --driver-memory 2g spark/top10_spark.py --dir raw --seuil 1000 \
       > results/top10_spark_affichage.txt 2> logs/06_chrono_spark_$i.log
  fin=$(date +%s.%N)
  # durée en secondes avec une décimale
  duree=$(awk -v d="$debut" -v f="$fin" 'BEGIN { printf "%.1f", f - d }')
  echo "spark,$i,$duree" >> results/temps_spark.csv
  echo "Exécution $i : $duree s"
done

echo "Durées enregistrées dans results/temps_spark.csv"