# using Revise
using CSV, StringEncodings, DataFrames

include("Span.jl")

struct Courses
    df::DataFrame
    sections::GroupedDataFrame
    sigle::GroupedDataFrame
    sect::Dict{String, Vector{String}}
end

function Courses(fas::String, med::String)
    fas_df = CSV.read(open(fas, enc"ISO-8859-1"), DataFrame, header=9, footerskip=7)
    med_df = CSV.read(open(med, enc"ISO-8859-1"), DataFrame, header=9, footerskip=7)
    df = vcat(fas_df, med_df)
    sigle = df[!, "Mat."] .* " " .* df[!, "Num. rép."]
    c_df = DataFrame(sigle=sigle,
                     nom=df[!, "Titre"],
                     volet=df[!, "Volet"],
                     section=df[!, "Sect."],
                     statut=df[!, "Statut"],
                     jour=df[!, "Jour"],
                     de=df[!, "De"],
                     a=df[!, "A"],
                     du=df[!, "Du"],
                     au=df[!, "Au"]
    )
    sections_df = groupby(c_df, ["sigle", "section"])
    sigle_df = groupby(c_df, "sigle")
    sect = Dict{String, Vector{String}}()
    for k in keys(sigle_df)
        subdf = sigle_df[k]
        sect[last(subdf.sigle)] = unique(subdf.section)
    end
    Courses(c_df, sections_df, sigle_df, sect)
end

function spans(c::Courses, sigle::String)
    d = Dict{NTuple{2, String},Vector{Span}}()
    df = c.sigle[(sigle,)]
    volSec = [NTuple{2, String}((row.volet, row.section)) for row in eachrow(c.sigle[(sigle,)])] |> unique
    for (volet, sec) in volSec
        vs_df = df[df.volet .== volet .&& df.section .== sec,:]
        d[(volet, sec)] = reduce(vcat, [expand(row.de, row.a, row.du, row.au) for row in eachrow(vs_df)])
    end
    d
end

# function spans(d::Dict{Tuple{String, String}, Vector{Span}}, t::Tuple{String, String})

# end

# ## test
# d = spans(c, "IFT 1015")

# k = keys(d)
# for a in k, b in k
#     a ≥ b && continue
#     println("$a vs. $b = $(conflict(d[a], d[b]))")
#     println(conflict_dt(d[a], d[b]))
# end

