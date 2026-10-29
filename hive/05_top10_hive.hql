-- Partie 5 : top 10 des films par moyenne pondérée façon IMDb
-- score = (n x moyenne + m x C) / (n + m), avec m = seuil et C = moyenne de toutes les notes
-- Test    : hive --hivevar db=movielens_sample --hivevar seuil=10 -f hive/05_top10_hive.hql
-- Complet : hive --hivevar db=movielens --hivevar seuil=1000 -f hive/05_top10_hive.hql

USE ${hivevar:db};
SET hive.cli.print.header=true;
SET hive.mapred.mode=nonstrict;
SET hive.strict.checks.cartesian.product=false;

-- Etape 1 : une seule lecture des notes, on résume chaque film en une ligne
DROP TABLE IF EXISTS stats_films;
CREATE TEMPORARY TABLE stats_films AS
SELECT movieId,
       COUNT(*)    AS nb_notes,
       AVG(rating) AS note_moyenne,
       SUM(rating) AS somme_notes
FROM ratings_raw
GROUP BY movieId;

-- Moyenne générale C (affichée pour vérification)
SELECT SUM(somme_notes) / SUM(nb_notes) AS moyenne_generale_c
FROM stats_films;

-- Etape 2 : score pondéré des films avec au moins seuil notes, puis rang
DROP TABLE IF EXISTS top10_hive;
CREATE TABLE top10_hive AS
SELECT rang, movieId, title, nb_notes,
       ROUND(note_moyenne, 4) AS note_moyenne,
       ROUND(score, 4)        AS score_pondere
FROM (
  SELECT x.*,
         ROW_NUMBER() OVER (ORDER BY score DESC, nb_notes DESC) AS rang
  FROM (
    SELECT s.movieId, m.title, s.nb_notes, s.note_moyenne,
           (s.nb_notes * s.note_moyenne + ${hivevar:seuil} * g.c) / (s.nb_notes + ${hivevar:seuil}) AS score
    FROM stats_films s
    CROSS JOIN (SELECT SUM(somme_notes) / SUM(nb_notes) AS c FROM stats_films) g
    JOIN movies m ON s.movieId = m.movieId
    WHERE s.nb_notes >= ${hivevar:seuil}
  ) x
) t
WHERE rang <= 10;

-- Résultat écrit aussi dans notre dossier HDFS (une colonne par tabulation)
INSERT OVERWRITE DIRECTORY '/user/ubuntu/movielens/output/hive/${hivevar:db}'
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
SELECT * FROM top10_hive ORDER BY rang;

-- Affichage du top 10
SELECT * FROM top10_hive ORDER BY rang;