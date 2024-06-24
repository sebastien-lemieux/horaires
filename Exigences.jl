using Unicode

# struct Exigence
#     # Undecided
# end

function scrapeExigence(sigle::Symbol)
    sigle_str = replace(string(sigle), '_' => '-') |> lowercase
    cours_html = read_html("https://admission.umontreal.ca/cours-et-horaires/cours/$sigle_str/")

    sess = html_elements(cours_html, ".cours-sommaire ul li") # |> println # [2]
    sess_sym = Symbol[]
    for s in sess
        if (html_elements(s, "b")[1] |> html_text3 |> strip) == "Trimestres"
            s_str = html_elements(s, "p")[1] |> html_text3 |> strip
            for m in eachmatch(r"(Été|Hiver|Automne) (\d{4})", s_str)
                push!(sess_sym, Symbol(Unicode.normalize(m[1], stripmark=true)))
            end
        end
    end

    req_str = ""
    exigence_html = html_elements(cours_html, ".cours-exigence")
    if !isempty(exigence_html)
        req_str = html_elements(exigence_html, "p") |> html_text3 |> first |> uppercase |> strip
    end
    return (sess_sym, req_str)
end

# scrapeExigence(:STT_3510)

function scrapeExigences!(prog::Program) # Takes a few minutes... done once
    session = Vector{Symbol}[]
    req_str = String[]
    for sigle in prog.courses.sigle
        println(sigle)
        if string(sigle)[1:3] == "HEC"
            push!(session, eltype(session)()) # No access to 
            push!(req_str, "") # No access to 
        else
            tmp_s, tmp_r = scrapeExigence(sigle)
            push!(session, tmp_s)
            push!(req_str, tmp_r)
        end
    end
    prog.courses.session = session
    prog.courses.req_str = req_str
    prog.courses.A = :Automne .∈ prog.courses.session
    prog.courses.H = :Hiver .∈ prog.courses.session
    prog.courses.E = :Ete .∈ prog.courses.session
end

countIFT(done) = 0 # To be done

function parse_prealable(str::AbstractString)

    if match(r"COLLÈGE", str) !== nothing # Don't consider CEGEP courses
        # println("COLLEGE warning: $str")
        return (done -> true)
    end

    m = match(r"(?<cr>[0-9]+) CRÉDITS DE SIGLE IFT", str)
    if m !== nothing
        # println(m["cr"])
        cr = parse(Int, m["cr"])
        return done -> (countIFT(done) >= cr)
    end

    # Parse logic expression for prereq
    str = replace(str,
                  r"(?<mat>[A-Z]{3})(?<num>[0-9]{4}[A-Z]?)" => s"∈(:\g<mat>_\g<num>, done)",
                  "ET" => "*",
                  "OU" => "+",
                  "COMPÉTENCE ÉQUIVALENTE." => "",
                  "12 CRÉDITS" => "",
                  "," => "")
    println(str)
    return eval(Meta.parse("$str"))
end

# parse_equivalents(str::AbstractString)::Function = (done -> true) # To be done, if useful
# parse_concomitants(str::AbstractString)::Function = (done -> true) # To be done, if useful

# const ex_types = Dict("PRÉALABLES" => parse_prealable, "PRÉALABLE" => parse_prealable,
#                       "ÉQUIVALENTS" => parse_equivalents, "CONCOMITANTS" => parse_concomitants)

# function generateTestFunc!(prog::Program)
#     test = Function[]
#     for row in eachrow(prog.courses)
#         # println("$sigle: $ex")
#         parts = split(row.pr_text, "; ")
#         f = (done -> true)
#         for part in parts
#             ex_t = strip.(split(part, ":"))
#             if !isempty(ex_t[1]) && ex_t[1][1:5] == "PRÉA" && haskey(ex_types, ex_t[1])
#                 f = parse_prealable(strip(ex_t[2])) # ex_types[ex_t[1]](strip(ex_t[2])) # use Meta so they are not different functions
#             end
#             # @show ex
#         end
#         push!(test, f)
#     end

#     prog.courses.req = test
# end

# ****** Not done ******
function generateEq(str::String)
    parts = split(str, "; ")
    f = (done -> true)
    for part in parts
        ex_t = strip.(split(part, ":"))
        if !isempty(ex_t[1]) && ex_t[1][1:5] == "PRÉA" && haskey(ex_types, ex_t[1])
            f = parse_prealable(strip(ex_t[2])) # ex_types[ex_t[1]](strip(ex_t[2])) # use Meta so they are not different functions
        end
        # @show ex
    end

end
# ****** Not done ******
function generateEq!(prog::Program)
    test = Function[]
    for row in eachrow(prog.courses)
        # println("$sigle: $ex")
        parts = split(row.pr_text, "; ")
        f = (done -> true)
        for part in parts
            ex_t = strip.(split(part, ":"))
            if !isempty(ex_t[1]) && ex_t[1][1:5] == "PRÉA" && haskey(ex_types, ex_t[1])
                f = parse_prealable(strip(ex_t[2])) # ex_types[ex_t[1]](strip(ex_t[2])) # use Meta so they are not different functions
            end
            # @show ex
        end
        push!(test, f)
    end

    prog.courses.req = test
end

