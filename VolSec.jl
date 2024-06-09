using Combinatorics

_section(t::Tuple{String, String}) = t[2]

struct Schedule4
    sigle::String
    comb_df::DataFrame
end

function Schedule4(c, t, df, sigle)
    Schedule4(sigle, Dict([(k[1], d[k]) for k in keys(d) if _section(k) in t]))
end
Base.getindex(s::Schedule4, str::String) = s.d[str]

function schedules(c, sigle)
    df = spans(c, sigle)

    comb = allSections(unique(df.section))
    println(comb)
    for section in comb
        println(section)

        # sp = Span()
        push!(df, (section=section)) #, spans=nothing))
    end
    # s = _section.(keys(d)) |> unique
    # DataFrame(Dict([(t, Schedule4(c, t, d, sigle)) for t in comb]))
end
# spans(c, "IFT 1015")
# schedules(c, "IFT 1015")
# schedules(c, "BCM 2550")

function conflict(s_a::Schedule4, s_b::Schedule4)
    df = DataFrame()
    for k_a in keys(s_a.d), k_b in keys(s_b.d)
        dt = conflict_dt(s_a[k_a], s_b[k_b])
        isempty(dt) && continue
        d[(k_a, k_b)] = dt
    end
    d
    # d = Dict{Tuple{String, String}, Vector{Span}}()
    # for k_a in keys(s_a.d), k_b in keys(s_b.d)
    #     dt = conflict_dt(s_a[k_a], s_b[k_b])
    #     isempty(dt) && continue
    #     d[(k_a, k_b)] = dt
    # end
    # d
end

function allSections(v::Vector{String})
    th = String[]
    tp = String[]
    for s in v
        (length(s) == 1) ? push!(th, s) : push!(tp, s)
    end
    if isempty(tp)
        return [[x] for x in th]
    else
        return [[x,y] for x in th for y in tp if x[1] == y[1]]
    end
end

compatible(a, b) = nothing
_str(t) = join(t, "+")

function compatible(s_a::T, s_b::T) where T <: Dict{Vector{String}, Schedule4}
    k_a = keys(s_a)
    k_b = keys(s_b)
    res = String[]
    for a in k_a, b in k_b
        conf = conflict(s_a[a], s_b[b])
        isempty(conf) && push!(res, "$(_str(a)) et $(_str(b))")
    end
    res
end

function conflict(s_a::T, s_b::T) where T <: Dict{Vector{String}, Schedule4}
    k_a = keys(s_a) |> collect |> sort
    k_b = keys(s_b) |> collect |> sort
    res = String[]
    df = DataFrame(sigle_a=String[], ) #####################################
    for a in k_a, b in k_b
        sched_a = s_a[a]
        sched_b = s_b[b]
        conf = conflict(sched_a, sched_b)
        isempty(conf) && continue
        for (k,v) in conf
            println("$(sched_a.sigle) ($(k[1]), $(join(a, "-"))) - $(sched_b.sigle) ($(k[2]), $(join(b, "-"))): $(inWeek(first(v)))")
        end
        # "$(s_a[a].sigle) () $(s_a[a].sigle)"
        # clashes = join(["$(k[1])/$(k[2])" for k in keys(conf)], ", ")
        # push!(res, "Conflit: $(_str(a)) vs. $(_str(b)): $clashes")
        # push!(res, conf)
    end
    res
end