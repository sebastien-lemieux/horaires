# Points d'entrés:
- do_it.jl: Parse le programme + tous les horaires de cours puis "optimise" un horaire de 15 crédits sans conflits.
- Program.jl: Pour récupérer la structure d'un programme, extraire les exigences des blocs en termes de crédits.
- Schedules.jl: Pour organiser, parser et acceder à tous les horaires des cours FAS et FacMed.
- Span.jl: Représente une plage horaire (un cours à une date), l'horaire d'un cours complet est un vecteur de Span.
- A2024_FAS.csv: Horaire de tous les cours de la FAS.
- A2024_FMed.csv: Horaire de tous les cours de la FacMed.

# Pas important:
- JuMP/test_jump.jl: Petit exercice pour tester JuMP+GLPK.
- data.jld2: Contient tous les horaires, programme, préalables et sections, prêt à l'utilisation. Permet d'éviter le parsing de toutes ces données à chaque fois. Le fichier est créé après la première collecte de données et réutilisé par la suite (effacer pour mettre à jour).

# Mises à jours des horaires:
- FAS: 2024-06-01
- FMed: 2024-06-01
