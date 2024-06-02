# using Revise
using CSV, StringEncodings, DataFrames

include("Span.jl")

struct Courses4
    df::DataFrame
    sections::GroupedDataFrame
    sigle::GroupedDataFrame
    sect::Dict{String, Vector{String}}
end

function Courses4(fas::String, med::String)
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
    sect = Dict{String, Vector{String}}()
    for subdf in c.sigle
        sect[last(subdf.sigle)] = unique(subdf.section)
    end
    Courses4(c_df, groupby(c_df, ["sigle", "section"]), groupby(c_df, "sigle"), sect)
end

function spans(c::Courses4, sigle::String) # ::Dict{NTuple{2, String},Vector{Span}}
    d = Dict{NTuple{2, String},Vector{Span}}()
    df = c.sigle[(sigle,)]
    volSec = [NTuple{2, String}((row.volet, row.section)) for row in eachrow(c.sigle[(sigle,)])] |> unique
    for (volet, sec) in volSec
        vs_df = df[df.volet .== volet .&& df.section .== sec,:]
        d[(volet, sec)] = reduce(vcat, [expand(row.de, row.a, row.du, row.au) for row in eachrow(vs_df)])
    end
    d
end
d = spans(c, "MAT 1400")

k = keys(d)
for a in k, b in k
    a ≥ b && continue
    println("$a vs. $b = $(conflict(d[a], d[b]))")
    println(conflict_dt(d[a], d[b]))
end

