**Objectif:** Suite d'outils à la ligne de commande (ou via REPL Julia) permettant de gérer les horaires, optimiser les sessions pour éviter les conflits d'horaire et maximiser les cours préférés. Rapport des conflits d'horaire existant. Les données d'horaire sont téléchargée à la première utilisation d'une API mise en place au DIRO.

### Requis:
- Installation de Julia via [JuliaUp](https://github.com/JuliaLang/juliaup).
- Pour l'optimisation avec Gurobi (*Mixed-Integer Programming optimizer*):
  - Obtenir une licence académique (gratuite) pour [Gurobi](https://portal.gurobi.com/iam/login/).
  - Lier le module Gurobi.jl à la licence obtenue: [instructions](https://github.com/jump-dev/Gurobi.jl?tab=readme-ov-file#installation).

### To do:
- Convertir les req en contraintes
- Intégration du préalable basé sur le nombre de crédit IFT.
- Prendre compte des équivalences définies par l'UdeM
- Si j'ai cours XYZ, quels cours je peux prendre au programme (et le bloc).

### Points d'entrées au code:
- **do_it.jl:** Parse le programme + tous les horaires de cours puis "optimise" un horaire de 15 crédits sans conflits.
- **Program.jl:** Pour récupérer la structure d'un programme, extraire les exigences des blocs en termes de crédits.
- **Schedules.jl:** Pour organiser, parser et accéder à tous les horaires des cours FAS et FacMed.
- **Span.jl:** Représente une plage horaire (un cours à une date), l'horaire d'un cours complet est un vecteur de Span.

### Pas important:
- **data.jld2:** Contient tous les horaires, programme, préalables et sections, prêt à l'utilisation. Permet d'éviter le parsing de toutes ces données à chaque fois. Le fichier est créé après la première collecte de données et réutilisé par la suite (effacer pour mettre à jour).

### Mises à jour des horaires par le DIRO: ?
- Toujours vérifier dans le centre étudiant.