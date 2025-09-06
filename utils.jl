using NamedArrays

function NamedMatrix(transf::F, path::AbstractString, ::Type{T}) where {F<:Function, T}
    lines = readlines(path)
    hdr = strip.(split(lines[1], ','))[1:end-1]
    n = length(hdr)
    A = Matrix{T}(undef, n, n)
    rnames = Vector{String}(undef, n)
    for (i, l) in enumerate(lines[2:n+1])
        parts = strip.(split(l, ','))
        println(parts[1:end-1])
        A[i, :] = transf.(parts[1:end-1])
        rnames[i] = parts[end]
    end
    NamedArray(A, (rnames, hdr), ("rows", "cols"))
end

# d = NamedMatrix(x -> ceil(Int, parse.(Float64, x)), "data/distances_finales.csv", Int)
# d["bas_rampe", "haut_rampe"]

function showsolution(model, semester_schedules, decision)
    println("Score: $(objective_value(model))")
    println("Nombre de crédits: $(sum(value(model[:done] .* courses[:,:credits])))")

    active_conflict.value = value.(active_conflict.var)
    report_c = active_conflict[active_conflict.value .< 1.0, :]
    active_bloc.min_v = value.(active_bloc.min)
    active_bloc.max_v = value.(active_bloc.max)
    o = (active_bloc.min_v .< 1.0 .|| active_bloc.max_v .< 1.0)
    report_b = active_bloc[o,:]
    println("Nb. de conflits à régler: $(nrow(report_c))")
    println("Nb. de bloc à problème: $(nrow(report_b))")


    println()
    choices = round.(Bool, value.(model[:decision_var]))
    for k=1:nb_s
        n_credits = sum(value(model[:decision_var][:,k] .* decision[:,:credits_eff]))
        println("Session $k ($(semester_schedules[k])) $n_credits crédits")
        for i=1:nb_d
            choices[i,k] && println("  $i: $(decision[i, :sigle]):$(decision[i, :msection])")
        end
    end
    return report_c, report_b
end

function getspan(decision, sigle, msection, semester)
    subset = (decision.sigle .== sigle .&& decision.msection .== msection .&& decision.semester .== semester)
    res = decision[subset,:span]
    return res[1]
end

function preferences!(courses, fn::String)
    f = open(fn, "r")
    for line in readlines(f)
        c, pref = strip.(split(line))
        courses[courses.sigle .== Symbol(c), :pref] .= parse(Float32, pref)
        # println(courses[courses.sigle .== Symbol(c), :])
    end
end

function inactivated_cst(active_conflict, active_bloc)

    active_conflict.value = value.(active_conflict.var)
    report_c = active_conflict[active_conflict.value .< 1.0, :]
    active_bloc.min_v = value.(active_bloc.min)
    active_bloc.max_v = value.(active_bloc.max)
    o = (active_bloc.min_v .< 1.0 .|| active_bloc.max_v .< 1.0)
    report_b = active_bloc[o,:]

    println(report_c)
    println(report_b)
end

