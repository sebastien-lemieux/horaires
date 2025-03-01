// typst watch test.typ data/test.pdf

#set page(width: 6in, height: auto, margin: 0pt)

#let course(x, y, str) = {
  grid.cell(x: x, y: y+1, rowspan: 3, fill: rgb("dddddd"), stroke: 0.1pt)[#text(size: 8pt)[#str]]
}

#let time(y, str) = {
  grid.cell(x: 0, y: y, align: right, fill: rgb("ffffff"), inset: 0.5em)[#text(size: 7pt, style: "italic", baseline: -7.5pt)[#str]]
}

#let time_cells = range(5).map(i => {
    if calc.even(i) {
      time(i + 1, str((i/2) + 8) + "h00")
    } else {
      time(i + 1, str(calc.floor(i/2) + 8) + "h30")
    }
  }
)

#grid(
  columns: (30pt,) + (1fr,) * (5),
  rows: (15pt,) * (25 + 1),
  gutter: 0pt,
  align: center + horizon,
  fill: rgb("ffffff"),
  ..time_cells,
  ..("Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi").enumerate().map(tuple => {
      let (i, str) = tuple
      grid.cell(x: i+1, y:0, fill: rgb("ffffff"))[#text(size: 7pt, style: "italic", weight: "bold")[#str]]
    }
  ),
  course(1, 0, "cours\n#1"),
  course(3, 2, "cours\n#2"),
)
