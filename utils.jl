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
    choices = round.(Bool, value.(model[:decision_var]))
    for k=1:nb_s
        println("Session $k ($(semester_schedules[k]))")
        for i=1:nb_d
            choices[i,k] && println("  $i: $(decision[i, :sigle]):$(decision[i, :msection])")
        end
    end
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

