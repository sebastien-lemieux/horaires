using Revise, Infiltrator
using HTTP, Gumbo, Cascadia, JSON3

html = String(read("data/baccalaureat-en-bio-informatique.html"))
root = parsehtml(html).root

txt(n) = strip(Gumbo.text(n))
firsttext(sel, node) = (m = first(eachmatch(Selector(sel), node)); m === nothing ? nothing : txt(m))

prog = Dict(
  "name" => firsttext(".programme-identification .programme-name", root),
  "number" => firsttext(".cycle-numero .numero", root),
)

segments = []

for seg in eachmatch(Selector("div.programme-segment"), root)
  seg_title = first(eachmatch(Selector(".description-segment h3"), seg))
  seg_note = first(eachmatch(Selector(".description-segment p"), seg))
  blocks = []
  for blk in eachmatch(Selector("section.bloc"), seg)
    h = first(eachmatch(Selector(".bloc-titre h4 span"), blk))
    sm = first(eachmatch(Selector(".bloc-titre small"), blk))
    htxt = h === nothing ? "" : txt(h)
    m = match(r"^Bloc\s+(\S+)\s*(.*)$", htxt)
    bcode = m === nothing ? nothing : m.captures[1]
    bname = m === nothing ? htxt : m.captures[2]
    bmeta = sm === nothing ? "" : txt(sm)
    btype = occursin("Obligatoire", bmeta) ? "Obligatoire" : occursin("Choix", bmeta) ? "Choix" : occursin("Option", bmeta) ? "Option" : nothing
    bcredits = something(match(r"(\d+(?:[.,]\d+)?)\s*crédit", bmeta), nothing)
    bcredits = bcredits === nothing ? nothing : replace(bcredits.captures[1], ',' => '.')
    courses = []
    for c in eachmatch(Selector("section.cours article.cour-detailles"), blk)
      a = first(eachmatch(Selector("a.stretched-link"), c))
      title = firsttext(".cour-intro p span", c)
      credits = firsttext(".cour-credit", c)
      push!(courses, Dict(
        "code" => (a === nothing ? nothing : txt(a)),
        "url" => (a === nothing ? nothing : get(a.attributes, "href", nothing)),
        "title" => title,
        "credits" => credits,
      ))
    end
    push!(blocks, Dict(
      "code" => bcode,
      "name" => isempty(bname) ? nothing : bname,
      "meta" => bmeta,
      "type" => btype,
      "credits_hint" => bcredits,
      "courses" => courses,
    ))
  end
  push!(segments, Dict(
    "id" => seg_title === nothing ? nothing : get(seg_title.attributes, "id", nothing),
    "title" => seg_title === nothing ? nothing : txt(seg_title),
    "note" => seg_note === nothing ? nothing : txt(seg_note),
    "blocks" => blocks,
  ))
end

prog["segments"] = segments
println(JSON3.write(prog; indent=2))
