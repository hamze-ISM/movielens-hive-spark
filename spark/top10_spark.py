"""
Partie 6 : top 10 des films MovieLens avec Spark (PySpark)
Même calcul que hive/05_top10_hive.hql : moyenne pondérée façon IMDb
    score = (n x moyenne + m x C) / (n + m), avec m = seuil et C = moyenne de toutes les notes

Test    : spark-submit --master "local[*]" --driver-memory 2g spark/top10_spark.py --dir sample --seuil 10
Complet : spark-submit --master "local[*]" --driver-memory 2g spark/top10_spark.py --dir raw --seuil 1000
"""
import argparse
import time

from pyspark.sql import SparkSession, Window
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, IntegerType, DoubleType, LongType

HDFS = "hdfs://localhost:8020/user/ubuntu/movielens"

# Paramètres : dossier des données (raw = complet, sample = échantillon) et seuil minimal de notes
parser = argparse.ArgumentParser()
parser.add_argument("--dir", default="raw", choices=["raw", "sample"])
parser.add_argument("--seuil", type=int, default=1000)
parser.add_argument("--pause", action="store_true", help="attendre avant de fermer Spark, pour voir l'interface web")
args = parser.parse_args()

debut = time.time()

# Session Spark : 8 partitions après un regroupement suffisent sur un seul PC (200 par défaut)
spark = (SparkSession.builder
         .appName("top10_movielens")
         .config("spark.sql.shuffle.partitions", "8")
         .getOrCreate())
spark.sparkContext.setLogLevel("WARN")

# Notes : on donne le schéma, Spark n'a pas besoin de relire le fichier pour deviner les types
schema_notes = StructType([
    StructField("userId", IntegerType()),
    StructField("movieId", IntegerType()),
    StructField("rating", DoubleType()),
    StructField("ts", LongType()),
])
ratings = spark.read.csv(f"{HDFS}/{args.dir}/ratings", header=True, schema=schema_notes)

# Films : les titres qui contiennent une virgule sont entre guillemets
movies = (spark.read.csv(f"{HDFS}/{args.dir}/movies", header=True, quote='"', escape='"')
          .select(F.col("movieId").cast("int").alias("movieId"), "title"))

# Étape 1 : une ligne par film (nombre, moyenne et somme des notes)
stats = (ratings.groupBy("movieId")
         .agg(F.count("*").alias("nb_notes"),
              F.avg("rating").alias("note_moyenne"),
              F.sum("rating").alias("somme_notes"))
         .cache())   # gardé en mémoire : on s'en sert deux fois (pour C puis pour le classement)

# Moyenne générale C = somme de toutes les notes / nombre total de notes
C = stats.agg(F.sum("somme_notes") / F.sum("nb_notes")).first()[0]
print(f"Moyenne générale C = {C}")

# Étape 2 : score pondéré des films avec au moins m notes, puis rang
m = args.seuil
ordre = Window.orderBy(F.desc("score"), F.desc("nb_notes"))   # même départage que Hive
top10 = (stats.filter(F.col("nb_notes") >= m)
         .withColumn("score", (F.col("nb_notes") * F.col("note_moyenne") + m * C) / (F.col("nb_notes") + m))
         .join(movies, on="movieId")
         .withColumn("rang", F.row_number().over(ordre))
         .filter(F.col("rang") <= 10)
         .select("rang", "movieId", "title", "nb_notes",
                 F.round("note_moyenne", 4).alias("note_moyenne"),
                 F.round("score", 4).alias("score_pondere"))
         .orderBy("rang"))

# Résultat dans HDFS : un seul fichier, colonnes séparées par des tabulations (comme Hive)
top10.coalesce(1).write.mode("overwrite").option("sep", "\t").csv(f"{HDFS}/output/spark/{args.dir}")

top10.show(truncate=False)
print(f"Durée du traitement Spark : {time.time() - debut:.1f} s")

# Option --pause : laisse le temps d'ouvrir http://localhost:4040 pour les captures
if args.pause:
    input("Interface Spark ouverte sur http://localhost:4040 - appuie sur Entrée pour terminer...")

spark.stop()