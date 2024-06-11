

# struct Exigence
#     # Undecided
# end

function scrapeExigence(sigle::Symbol)
    sigle_str = replace(string(sigle), '_' => '-') |> lowercase
    cours_html = read_html("https://admission.umontreal.ca/cours-et-horaires/cours/$sigle_str/")
    exigence_html = html_elements(cours_html, ".cours-exigence")
    isempty(exigence_html) && return ""
    return html_elements(exigence_html, "p") |> html_text3 |> first |> uppercase |> strip
end

function scrapeExigences!(prog::Program) # Takes a few minutes... done once
    ex = String[]
    for sigle in prog.courses.sigle
        println(sigle)
        if string(sigle)[1:3] == "HEC"
            push!(ex, "") # No access to 
        else
            push!(ex, scrapeExigence(sigle))
        end
    end
    prog.courses.pr_text = ex
end

countIFT(done) = 0 # To be done

function parse_prealable(str::String)::Function

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
                  "ET" => "&&",
                  "OU" => "||",
                  "COMPÉTENCE ÉQUIVALENTE." => "false",
                  "12 CRÉDITS" => "false",
                  "," => "&&")
    return eval(Meta.parse("done -> $str"))
end

parse_equivalents(str::String)::Function = (done -> true) # To be done, if useful
parse_concomitants(str::String)::Function = (done -> true) # To be done, if useful

const ex_types = Dict("PRÉALABLES" => parse_prealable, "PRÉALABLE" => parse_prealable,
                      "ÉQUIVALENTS" => parse_equivalents, "CONCOMITANTS" => parse_concomitants)

function generateTestFunc!(prog::Program)
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

    prog.courses.pr_test = test
end

# scrapeExigences!(prog)
# generateTestFunc!(prog)

# new_done = Set([:IFT_1065, :IFT_1016, :BCM_2550, :BIN_1002, :BCM_1501, :IFT_1215, :IFT_2125, :MAT_1600, :MAT_1978, :IFT_1025])

# prog[:IFT_1025].pr_test