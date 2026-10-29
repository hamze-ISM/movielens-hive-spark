-- Partie 3 (b) : contrôles de qualité sur les films et les dates (Véracité)
-- Test    : hive --hivevar db=movielens_sample -f hive/03_qualite_films_dates.hql
-- Complet : hive --hivevar db=movielens -f hive/03_qualite_films_dates.hql

USE ${hivevar:db};
SET hive.cli.print.header=true;

-- 4) Notes portant sur un film absent de movies.csv
SELECT COUNT(*) AS notes_film_inconnu
FROM ratings_raw r
LEFT JOIN movies m ON r.movieId = m.movieId
WHERE m.movieId IS NULL;

-- 5) Table des films : identifiants en double ou illisibles
SELECT COUNT(*) AS nb_films,
       COUNT(DISTINCT movieId) AS nb_movieid_distincts,
       SUM(CASE WHEN movieId IS NULL THEN 1 ELSE 0 END) AS movieid_illisible
FROM movies;

-- 6) Nombre de notes par année (grâce aux dates converties)
SELECT rating_year, COUNT(*) AS nb
FROM ratings_dates
GROUP BY rating_year
ORDER BY rating_year;