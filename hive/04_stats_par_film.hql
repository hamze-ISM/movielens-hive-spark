-- Partie 4 : nombre de notes et note moyenne de chaque film (sert à choisir le seuil)
-- Test    : hive --hivevar db=movielens_sample -f hive/04_stats_par_film.hql
-- Complet : hive --hivevar db=movielens -f hive/04_stats_par_film.hql

USE ${hivevar:db};
SET hive.cli.print.header=true;

-- Une ligne par film noté
SELECT movieId,
       COUNT(*)    AS nb_notes,
       AVG(rating) AS note_moyenne
FROM ratings_raw
GROUP BY movieId;