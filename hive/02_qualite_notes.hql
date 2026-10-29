-- Partie 3 (a) : contrôles de qualité sur les notes (Véracité)
-- Test    : hive --hivevar db=movielens_sample -f hive/02_qualite_notes.hql
-- Complet : hive --hivevar db=movielens -f hive/02_qualite_notes.hql

USE ${hivevar:db};
SET hive.cli.print.header=true;

-- 1) Un seul passage sur les notes : volume, valeurs manquantes, notes invalides, période couverte
-- Une valeur vide ou illisible devient NULL dans Hive
SELECT
  COUNT(*) AS nb_notes,
  SUM(CASE WHEN userId  IS NULL THEN 1 ELSE 0 END) AS userid_manquant,
  SUM(CASE WHEN movieId IS NULL THEN 1 ELSE 0 END) AS movieid_manquant,
  SUM(CASE WHEN rating  IS NULL THEN 1 ELSE 0 END) AS note_manquante,
  SUM(CASE WHEN ts      IS NULL THEN 1 ELSE 0 END) AS ts_manquant,
  SUM(CASE WHEN rating < 0.5 OR rating > 5 OR rating * 2 <> FLOOR(rating * 2) THEN 1 ELSE 0 END) AS note_invalide,
  MIN(rating) AS note_min,
  MAX(rating) AS note_max,
  from_unixtime(MIN(ts)) AS premiere_note,
  from_unixtime(MAX(ts)) AS derniere_note,
  COUNT(DISTINCT userId)  AS nb_utilisateurs,
  COUNT(DISTINCT movieId) AS nb_films_notes
FROM ratings_raw;

-- 2) Répartition des notes
SELECT rating, COUNT(*) AS nb
FROM ratings_raw
GROUP BY rating
ORDER BY rating;

-- 3) Doublons : un même utilisateur qui note le même film plusieurs fois
SELECT COUNT(*) AS paires_en_double,
       COALESCE(SUM(nb - 1), 0) AS lignes_en_trop
FROM (
  SELECT userId, movieId, COUNT(*) AS nb
  FROM ratings_raw
  GROUP BY userId, movieId
  HAVING COUNT(*) > 1
) d;
