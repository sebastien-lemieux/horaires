using TidierVest, Gumbo, DataFrames, HTTP

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

struct Program
    blocs::DataFrame
    courses::DataFrame
end

function Program(url)
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
                         sigle=Symbol(sigle_str)))
        end
    end

    Program(b_df, c_df)
end

Base.getindex(p::Program, sym::Symbol) = p.courses[findfirst(p.courses.sigle .== sym),:]
sigle_sym(str) = Symbol(str[1:3] * '_' * str[4:end])

