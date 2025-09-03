using CSV

df = DataFrame(CSV.File("distances.csv"))
pav_v = Symbol.(df[!,end])
pav = Dict([p => i for (i,p) in enumerate(pav_v)])
dist_m = Matrix{Float64}(df[!, 1:end-1])

function getdist(a::Symbol, b::Symbol)
    (a == :missing || b == :missing) && return 0.0
    return dist_m[pav[a], pav[b]]
end

getdist(:station_jt, :station_cdn)