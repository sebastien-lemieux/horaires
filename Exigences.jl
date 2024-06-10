

struct Exigence
    # Undecided
end

function getExigence(sigle::Symbol)
    sigle_str = replace(string(sigle), '_' => '-') |> lowercase
    cours_html = read_html("https://admission.umontreal.ca/cours-et-horaires/cours/$sigle_str/")
    exigence_html = html_elements(cours_html, ".cours-exigence")
    isempty(exigence_html) && return ""
    return html_elements(exigence_html, "p") |> html_text3 |> first |> uppercase |> strip
end

function downloadExigences(prog::Program)
    exigence_d = Dict{Symbol, String}()

    for sigle in prog.courses.sigle
        println(sigle)
        haskey(exigence_d, sigle) && continue
        string(sigle)[1:3] == "HEC" && continue
        exigence_d[sigle] = getExigence(sigle)
    end
    return exigence_d
end

countIFT(done) = 0
function parse_prealable(str)
    if match(r"COLLÈGE", str) !== nothing
        println("COLLEGE warning: $str")
        return (done -> true)
    end
    m = match(r"(?<cr>[0-9]+) CRÉDITS DE SIGLE IFT", str)
    if m !== nothing
        println(m["cr"])
        cr = parse(Int, m["cr"])
        return done -> (countIFT(done) >= cr)
    end

    str = replace(str,
                  r"(?<mat>[A-Z]{3})(?<num>[0-9]{4}[A-Z]?)" => s"∈(:\g<mat>_\g<num>, done)",
                  "ET" => "&&",
                  "OU" => "||",
                  "COMPÉTENCE ÉQUIVALENTE." => "false",
                  "12 CRÉDITS" => "false",
                  "," => "&&")
    return eval(Meta.parse("done -> $str"))
end

parse_equivalents(str) = (done -> true)
parse_concomitants(str) = (done -> true)
ex_types = Dict("PRÉALABLES" => parse_prealable, "PRÉALABLE" => parse_prealable,
                "ÉQUIVALENTS" => parse_equivalents, "CONCOMITANTS" => parse_concomitants)

new_done = Set([:IFT_1065, :IFT_1025, :BCM_2550, :BIN_1002, :BCM_1501, :IFT_1215, :IFT_2125, :MAT_1600, :MAT_1978, :IFT_1025])

test_d = Dict{Symbol, Function}()
for (sigle, ex) in exigence_d
    println("$sigle: $ex")
    parts = split(ex, "; ")
    for part in parts
        ex_t = strip.(split(part, ":"))
        isempty(ex_t[1]) && continue
        if !haskey(ex_types, ex_t[1])
            println("Problem parsing: $(ex_t[1])")
            continue
        end
        test_d[sigle] = ex_types[ex_t[1]](strip(ex_t[2]))
    end
end

# str = "IFT2125 ET MAT1600 ET (MAT1978 OU (MAT1720 ET STT1700))"
# str = "IFT1025"
# str = replace(str, r"(?<mat>[A-Z]{3})(?<num>[0-9]{4}[A-Z]?)" => s"∈(:\g<mat>_\g<num>, done)", "ET" => "&&", "OU" => "||")
# f = Meta.parse("done -> $str")


# g = eval(f)
# g(new_done)

str = "30 CRÉDITS DE SIGLE IFT"
m = match(r"(?<cr>[0-9]+) CRÉDITS DE SIGLE IFT", str)

f = (done -> countIFT(done) ≥ 15)

f(new_done)