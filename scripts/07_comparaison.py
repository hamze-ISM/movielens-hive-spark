"""
Partie 7 : comparaison Hive / Spark sur trois points
  1) même résultat ?  2) temps d'exécution  3) facilité d'écriture (lignes de code)
Utilisation (depuis la racine du projet) : python3 scripts/07_comparaison.py
"""
import csv
import pandas as pd

COLONNES = ["rang", "movieId", "title", "nb_notes", "note_moyenne", "score_pondere"]

# ---------- 1) Même résultat ? ----------
# Les fichiers de Hive et Spark n'ont pas d'en-tête, on donne les noms de colonnes
hive = pd.read_csv("results/top10_hive.tsv", sep="\t", names=COLONNES, quoting=csv.QUOTE_NONE)
spark = pd.read_csv("results/top10_spark.tsv", sep="\t", names=COLONNES, quoting=csv.QUOTE_NONE)
ref = pd.read_csv("results/top10_reference_pandas.csv")   # référence calculée avec pandas (Partie 4)

memes_films = (hive["movieId"].tolist() == spark["movieId"].tolist() == ref["movieId"].tolist())
memes_nb_notes = (hive["nb_notes"].tolist() == spark["nb_notes"].tolist() == ref["nb_notes"].tolist())
# écart le plus grand entre les scores (Hive et Spark arrondissent à 4 décimales)
ecart_hive_spark = (hive["score_pondere"] - spark["score_pondere"]).abs().max()
ecart_hive_ref = (hive["score_pondere"] - ref["score_pondere"]).abs().max()

comparaison = pd.DataFrame({
    "rang": hive["rang"],
    "film": hive["title"],
    "score_hive": hive["score_pondere"],
    "score_spark": spark["score_pondere"],
    "score_reference": ref["score_pondere"].round(4),
})
comparaison.to_csv("results/comparaison_resultats.csv", index=False)

print("=== 1) Même résultat ? ===")
print(f"Mêmes films dans le même ordre (Hive, Spark, pandas) : {memes_films}")
print(f"Mêmes nombres de notes : {memes_nb_notes}")
print(f"Écart max des scores Hive / Spark : {ecart_hive_spark:.6f}")
print(f"Écart max des scores Hive / référence pandas : {ecart_hive_ref:.6f}")
print(comparaison.to_string(index=False))

# ---------- 2) Temps d'exécution ----------
temps = pd.concat([pd.read_csv("results/temps_hive.csv"), pd.read_csv("results/temps_spark.csv")])
resume = temps.groupby("outil")["duree_s"].agg(["min", "median", "max"]).round(1)
rapport = resume.loc["hive", "median"] / resume.loc["spark", "median"]
resume.to_csv("results/comparaison_temps.csv")

print("\n=== 2) Temps d'exécution sur le jeu complet (secondes, 3 exécutions) ===")
print(resume.to_string())
print(f"Spark est {rapport:.1f} fois plus rapide que Hive (rapport des médianes)")

# ---------- 3) Facilité d'écriture : nombre de lignes ----------
def compter_lignes(chemin, debut_commentaire):
    """Compte les lignes totales, vides, de commentaire et de code utile d'un fichier."""
    total = vides = commentaires = 0
    dans_docstring = False
    with open(chemin, encoding="utf-8") as f:
        for ligne in f:
            l = ligne.strip()
            total += 1
            if l.startswith('"""'):
                commentaires += 1
                if l.count('"""') == 1:      # docstring sur plusieurs lignes : on entre ou on sort
                    dans_docstring = not dans_docstring
            elif dans_docstring or l.startswith(debut_commentaire):
                commentaires += 1
            elif l == "":
                vides += 1
    return {"total": total, "vides": vides, "commentaires": commentaires,
            "code_utile": total - vides - commentaires}

lignes = pd.DataFrame({
    "Hive (hive/05_top10_hive.hql)": compter_lignes("hive/05_top10_hive.hql", "--"),
    "Spark (spark/top10_spark.py)": compter_lignes("spark/top10_spark.py", "#"),
}).T
lignes.to_csv("results/comparaison_lignes.csv")

print("\n=== 3) Nombre de lignes des scripts ===")
print(lignes.to_string())