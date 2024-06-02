using Combinatorics

_section(t::Tuple{String, String}) = t[2]

struct Schedule
    d::Dict{String, Vector{Span}}
end

Schedule(c, t, d) = Schedule(Dict([(k[1], d[k]) for k in keys(d) if _section(k) in t]))
Base.getindex(s::Schedule, str::String) = s.d[str]

function conflict(s_a::Schedule, s_b::Schedule)
    d = Dict{Tuple{String, String}, Vector{Span}}()
    for k_a in keys(s_a.d), k_b in keys(s_b.d)
        # println("VOLET $k_a vs. $k_b")
        dt = conflict_dt(s_a[k_a], s_b[k_b])
        isempty(dt) && continue
        d[(k_a, k_b)] = dt
    end
    d
end

function schedules(c, sigle)
    d = spans(c, sigle)
    s = _section.(keys(d)) |> unique
    comb = [(a, b) for (a, b) in combinations(s, 2) if startswith(a, b) || startswith(b, a)]
    Dict([(t, Schedule(c, t, d)) for t in comb])
end

compatible(a, b) = nothing
_str(t) = "$(t[1])+$(t[2])"

function compatible(s_a::T, s_b::T) where T <: Dict{Tuple{String, String}, Schedule}
    k_a = keys(s_a)
    k_b = keys(s_b)
    res = String[]
    for a in k_a, b in k_b
        conf = conflict(s_a[a], s_b[b])
        isempty(conf) && push!(res, "$(_str(a)) and $(_str(b))")
    end
    res
end
function conflict(s_a::T, s_b::T) where T <: Dict{Tuple{String, String}, Schedule}
    k_a = keys(s_a)
    k_b = keys(s_b)
    res = String[]
    for a in k_a, b in k_b
        conf = conflict(s_a[a], s_b[b])
        isempty(conf) && continue
        clashes = join(["$(k[1])/$(k[2])" for k in keys(conf)], ", ")
        push!(res, "Conflict: $(_str(a)) vs. $(_str(b)): $clashes")
    end
    res
end

# compatible(alt, alt_b)
