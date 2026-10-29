#!/bin/bash
# Partie 5 : lance le top 10 Hive plusieurs fois sur le jeu complet et note la durée de chaque exécution
# Utilisation (depuis la racine du projet) : bash scripts/05_chrono_hive.sh 3
set -e
N=${1:-3}
echo "outil,execution,duree_s" > results/temps_hive.csv

for i in $(seq 1 $N); do
  debut=$(date +%s.%N)
  hive --hivevar db=movielens --hivevar seuil=1000 -f hive/05_top10_hive.hql \
       > results/top10_hive_affichage.txt 2> logs/05_chrono_hive_$i.log
  fin=$(date +%s.%N)
  # durée en secondes avec une décimale
  duree=$(awk -v d="$debut" -v f="$fin" 'BEGIN { printf "%.1f", f - d }')
  echo "hive,$i,$duree" >> results/temps_hive.csv
  echo "Exécution $i : $duree s"
done

echo "Durées enregistrées dans results/temps_hive.csv"