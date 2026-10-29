-- Partie 3 : tables Hive sur les fichiers CSV stockés dans HDFS
-- Test    : hive --hivevar db=movielens_sample --hivevar dir=sample -f hive/01_creer_tables.hql
-- Complet : hive --hivevar db=movielens --hivevar dir=raw -f hive/01_creer_tables.hql

CREATE DATABASE IF NOT EXISTS ${hivevar:db};
USE ${hivevar:db};
SET hive.cli.print.header=true;

-- Table externe : Hive lit les fichiers sur place, supprimer la table ne supprime pas les données
-- ts = timestamp Unix en secondes (le mot timestamp est réservé dans Hive)
DROP TABLE IF EXISTS ratings_raw;
CREATE EXTERNAL TABLE ratings_raw (
  userId  INT,
  movieId INT,
  rating  DOUBLE,
  ts      BIGINT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/ubuntu/movielens/${hivevar:dir}/ratings'
TBLPROPERTIES ('skip.header.line.count'='1');

-- movies.csv contient des titres entre guillemets avec des virgules
-- OpenCSVSerde gère ces guillemets (virgule et guillemet double par défaut) mais lit tout comme du texte
DROP TABLE IF EXISTS movies_raw;
CREATE EXTERNAL TABLE movies_raw (
  movieId STRING,
  title   STRING,
  genres  STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS TEXTFILE
LOCATION '/user/ubuntu/movielens/${hivevar:dir}/movies'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Vue movies : movieId remis en entier pour pouvoir faire la jointure avec les notes
DROP VIEW IF EXISTS movies;
CREATE VIEW movies AS
SELECT CAST(movieId AS INT) AS movieId, title, genres
FROM movies_raw;

-- Vue ratings_dates : conversion du timestamp Unix en date lisible
DROP VIEW IF EXISTS ratings_dates;
CREATE VIEW ratings_dates AS
SELECT userId, movieId, rating, ts,
       from_unixtime(ts) AS rating_datetime,
       to_date(from_unixtime(ts)) AS rating_date,
       year(from_unixtime(ts)) AS rating_year
FROM ratings_raw;

-- Vérifications rapides
SHOW TABLES;
SELECT * FROM ratings_dates LIMIT 5;
SELECT * FROM movies WHERE movieId IN (11, 29, 40);