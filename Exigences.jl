
# req = filter(s -> match.(r"prerequisite_courses.*(et|ou)"i, s) ≠ nothing, vcat(split.(decision.req, "\n")...))

using Random, JuMP

struct Reqs
    model::Model # has var: doing[,] and done_before[,]
    d::Dict{Symbol, Int}
    courses::DataFrame
end
Base.getindex(r::Reqs, sigle::Symbol) = r.courses[r.d[sigle],:]

function Reqs(m::Model, c::DataFrame)
    d = Dict([c[i, :sigle] => i for i=1:nrow(c)])
    Reqs(m, d, c)
end

function to_expr(req::Reqs, i)
    strs = split(req.courses[i,:req], "\n")
    for str in strs
        m = match(r"^prerequisite_courses\s*:\s*(?<str>.*)", str)
        if m ≠ nothing
            str = replace(m["str"],
                r"(?<mat>[A-Z]{3})(?<num>[0-9]{4}[A-Z]?)" => s":\g<mat>\g<num>",
                r"\bET\b"i => "&",
                r"\bOU\b"i => "|",
                r"COMPÉTENCE ÉQUIVALENTE."i => "1",
                r"[0-9]+ CRÉDITS( DE SIGLE [A-Z]{3})?"i => "1",
                "," => "&") # Watch out for this
            # println(str)
            !isnothing(match(r"Collège"i, str)) && continue ## disregard cegep requirements
            return Meta.parse(str)
        end
    end
end

function gen(r::Reqs, expr::Expr, k::Int)
    if expr.head == :call
        # println("got a $(expr.args[1])")
        if expr.args[1] == :|
            a = @variable(r.model, binary=true) # indicator variable
            b = gen(r, expr.args[2], k)
            c = gen(r, expr.args[3], k)
            # println("generate constraint!")
            # println("a: $a")
            # println("b: $b")
            @constraint(r.model, a ≥ b)
            @constraint(r.model, a ≥ c)
            @constraint(r.model, a ≤ b + c)
            return a
        elseif expr.args[1] == :&
            a = @variable(r.model, binary=true) # indicator variable
            b = gen(r, expr.args[2], k)
            c = gen(r, expr.args[3], k)
            # println("generate constraint!")
            @constraint(r.model, a ≤ b)
            @constraint(r.model, a ≤ c)
            @constraint(r.model, a ≥ b + c - 1)
            return a
        end
    else
        throw("blip")
    end
end

function gen(r::Reqs, q::QuoteNode, k::Int)
    c = q.value
    if haskey(r.d, c)
        i = r.d[c]
        # println("Got $c -> $i")
        return r.model[:done_before][i,k]
    else
        return 0
    end
end

gen(r::Reqs, cst::Int, k::Int) = cst

#to_eq("BCM2502 ET IFT2015 et (BIO2041 ou MAT1978 ou STT1700)")
# req = Reqs(model, courses);
# zzz = to_expr(req, d[:IFT3395])
# gen(req, zzz, 2)
# all_constraints(model, include_variable_in_set_constraints=false)