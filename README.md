**Objectif:** Suite d'outils à la ligne de commande (ou via REPL Julia) permettant de gérer les horaires, optimiser les sessions pour éviter les conflits d'horaire et maximiser les cours préférés. Rapport des conflits d'horaire existant. Les fichiers avec les horaires ne peuvent être obtenus que par le responsable de programme (via Synchro Académique).

### Requis:
- Installation de Julia via [JuliaUp](https://github.com/JuliaLang/juliaup).
- Pour l'optimisation avec Gurobi (*Mixed-Integer Programming optimizer*):
  - Obtenir une licence académique (gratuite) pour [Gurobi](https://portal.gurobi.com/iam/login/).
  - Lier le module Gurobi.jl à la licence obtenue: [instructions](https://github.com/jump-dev/Gurobi.jl?tab=readme-ov-file#installation).

### To do:
- Intégration des préalables dans l'optimisation.
- Permettre d'indiquer les cours déjà faits (juste un fichier, indiquant dans quels blocs ils sont entrés aussi).
- Permettre de donner une préférence sur les cours qui restent à faire. Un CSV pourrait être généré avec toutes préférences à 0, l'utilisateur viendrait ensuite éditer.
- Si j'ai cours XYZ, quels cours je peux prendre au programme (et le bloc)

### Points d'entrées au code:
- **do_it.jl:** Parse le programme + tous les horaires de cours puis "optimise" un horaire de 15 crédits sans conflits.
- **Program.jl:** Pour récupérer la structure d'un programme, extraire les exigences des blocs en termes de crédits.
- **Schedules.jl:** Pour organiser, parser et accéder à tous les horaires des cours FAS et FacMed.
- **Span.jl:** Représente une plage horaire (un cours à une date), l'horaire d'un cours complet est un vecteur de Span.
- **A2024_FAS.csv:** Horaire de tous les cours de la FAS.
- **A2024_FMed.csv:** Horaire de tous les cours de la FacMed.

### Pas important:
- **JuMP/test_jump.jl:** Petit exercice pour tester JuMP+GLPK.
- **data.jld2:** Contient tous les horaires, programme, préalables et sections, prêt à l'utilisation. Permet d'éviter le parsing de toutes ces données à chaque fois. Le fichier est créé après la première collecte de données et réutilisé par la suite (effacer pour mettre à jour).

### Mises à jour des horaires:
- **FAS:** 2024-06-01
- **FMed:** 2024-06-01
