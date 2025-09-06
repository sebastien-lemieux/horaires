**Objectif:** Suite d'outils à la ligne de commande (ou via REPL Julia) permettant de gérer les horaires, optimiser les sessions pour éviter les conflits d'horaire et maximiser les cours préférés. Rapport des conflits d'horaire existant. Les données d'horaire sont téléchargée à la première utilisation d'une API mise en place au DIRO.

### Requis:
- Installation de Julia via [JuliaUp](https://github.com/JuliaLang/juliaup).
- Pour l'optimisation avec Gurobi (*Mixed-Integer Programming optimizer*):
  - Obtenir une licence académique (gratuite) pour [Gurobi](https://portal.gurobi.com/iam/login/).
  - Lier le module Gurobi.jl à la licence obtenue: [instructions](https://github.com/jump-dev/Gurobi.jl?tab=readme-ov-file#installation).

### To do:
- Addresser le bloc 02Z.
  - Ajouter à la décision le bloc dans lequel inscrire le cours
- Intégration du préalable basé sur le nombre de crédit IFT. (ignorée)
- Prendre compte des équivalences définies par l'UdeM. (équivalence pas au programme ignorées)
- Prendre compte des possibilités de concomittance. (ignorées)
- Outil: Si j'ai cours XYZ, quels cours je peux prendre au programme (et le bloc).

### Points d'entrées au code:
- **do_it.jl:** Parse le programme + tous les horaires de cours puis "optimise" un horaire de 15 crédits sans conflits.

### Mises à jour des horaires par le DIRO: ?
- Toujours confirmer les horaires dans le centre étudiant.