
function generateLHS(str, course_j, var)
    if match(r"COLLÈGE", str) !== nothing # Don't consider CEGEP courses
        # println("COLLEGE warning: $str")
        return Expr(:call, :identity, 1)
    end

    m = match(r"(?<cr>[0-9]+) CRÉDITS", str) ## ignore
    if m !== nothing
        # println(m["cr"])
        cr = parse(Int, m["cr"])
        return Expr(:call, :identity, 1)
    end

    str2 = replace(str,
        r"(?<mat>[A-Z]{3})(?<num>[0-9]{4}[A-Z]?)" => s":\g<mat>_\g<num>",
        "ET" => "*",
        "OU" => "+",
        "COMPÉTENCE ÉQUIVALENTE." => "",
        "12 CRÉDITS" => "",
        "," => "")
    eq1 = Meta.parse(str2)

    function _transf(expr, course_j, var)
        if isa(expr, Expr)
            new_args = [_transf(a, course_j, var) for a in expr.args[2:end]]
            return Expr(expr.head, expr.args[1], new_args...)
        elseif isa(expr, QuoteNode)
            i = get(course_j, expr.value, 0)
            i == 0 && return Expr(:call, :identity, 0)
            return :(($var)[$i])
        end
    end

    return _transf(eq1, course_j, var)
end

function generateLHS!(prog::Program, course_j, var)
    lhs = Union{Nothing,Expr}[]
    for row in eachrow(prog.courses)
        println("$(row.sigle): $(row.req_str)")
        parts = split(row.req_str, "; ")
        tmp_lhs = nothing
        for part in parts
            ex_t = strip.(split(part, ":"))
            if !isempty(ex_t[1]) && ex_t[1][1:5] == "PRÉA"
                tmp_lhs = generateLHS(strip(ex_t[2]), course_j, var)
            end
            # @show ex
        end
        println(tmp_lhs)
        push!(lhs, tmp_lhs)
    end

    prog.courses.req_lhs = lhs
end
# generateLHS!(prog, course_j, :done_var)

