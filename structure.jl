## Loads programme structures

using TidierVest, Gumbo, DataFrames, HTTP

prog = read_html("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/")
#prog = read_html("https://admission.umontreal.ca/programmes/maitrise-en-bio-informatique/structure-du-programme/")

blocs = html_elements(prog, [".bloc"])

bloc_noms = String[]
sigles = String[]
cour_noms = String[]
cour_credit = String[]

for b in blocs
    bn = split(html_text3(first(html_elements(b, "h4"))))[2]
    cours = html_elements(b, ".cour-detailles")
    for c in cours
        ci = html_elements(c, ".cour-intro")
        push!(bloc_noms, bn)
        push!(sigles, html_text3(first(html_elements(ci, ".stretched-link"))))
        push!(cour_noms, html_text3(first(html_elements(ci, "span"))))
        push!(cour_credit, first(html_text3(html_elements(c, ".cour-credit"))))
    end
end

prog_df = DataFrame(bloc=bloc_noms, sigle=sigles, nom=cour_noms, credit=[parse(Float32, first(split(c))) for c in cour_credit])
