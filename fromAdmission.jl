using DataFrames, TidierVest

# Old structure for a program obsolete, but usefull to extract course lists from
# Web scraping the admission.umontreal.ca webpages.
# struct Program
#     blocs::DataFrame
#     courses::DataFrame
# end

struct BlocCredits
    type::Symbol
    minimum::Int
    maximum::Int
end

function BlocCredits(str)
    tmp_min, tmp_max, tmp_cr = -1, -1, -1

    m = match(r"^(?<type>\w+) - (?<constraints>.*)\.$"i, str)
    type = Symbol(lowercase(m["type"]))

    for tmp in eachmatch(r"(?:(?<dir>minimum|maximum|) )?(?<cr>\d+) crédits"i, m["constraints"])
        if tmp["dir"] === nothing
            tmp_cr = parse(Int, tmp["cr"])
        elseif lowercase(tmp["dir"]) == "minimum"
            tmp_min = parse(Int, tmp["cr"])
        elseif lowercase(tmp["dir"]) == "maximum"
            tmp_max = parse(Int, tmp["cr"])
        end
    end

    if type == :obligatoire
        tmp_min = tmp_cr
        tmp_max = tmp_cr
    elseif type == :choix
        tmp_min = 0
        tmp_max = tmp_cr
    elseif type == :option
        tmp_min == -1 && (tmp_min = 0)
    end

    BlocCredits(type, tmp_min, tmp_max)
end

struct FromAdmission end
function Programs(url::String, ::Type{FromAdmission})
    println("from Admission")
    prog = read_html(url)
    blocs = html_elements(prog, [".bloc"])

    b_df = DataFrame()
    c_df = DataFrame()
    for b in blocs

        bid = Symbol(split(html_text3(first(html_elements(b, "h4"))))[2])
        bloc_credits = BlocCredits(html_text3(first(html_elements(b, "small"))))
        println("$bid : $bloc_credits")
        push!(b_df, (bid = bid, constraint=bloc_credits))

        cours = html_elements(b, ".cour-detailles")
        for c in cours
            ci = html_elements(c, ".cour-intro")
            #cr_str = html_text3(html_elements(c, ".cour-credit"))[1]
            #cr = parse(Int, match(r"(?<cr>\d+).0.*", cr_str)["cr"])
            sigle_str = replace(html_text3(html_elements(c, ".stretched-link") |> first), ' ' => '_')
            push!(c_df, (bloc=bid,
                         sigle=Symbol(sigle_str))) # ,
                         #nom = html_text3(first(html_elements(ci, "span")))) # ,
                         #credit = cr))
        end
    end

    return (b_df, c_df)
end
_, c_df1 = Programs("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/", FromAdmission)
_, c_df2 = Programs("https://admission.umontreal.ca/programmes/baccalaureat-en-biochimie-et-medecine-moleculaire/structure-du-programme/", FromAdmission)
all_c = vcat(c_df1.sigle, c_df2.sigle) |> sort |> unique
for c in all_c
    println(c)
end