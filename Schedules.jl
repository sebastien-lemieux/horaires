# using Revise
using CSV, StringEncodings, DataFrames

include("Span.jl")

struct Schedules
    df::DataFrame
    sections::GroupedDataFrame
    sigle::GroupedDataFrame
    sect::Dict{Symbol, Vector{String}}
end

Base.getindex(c::Schedules, sigle::Symbol, section::String) = c.sections[(sigle, section)]
Base.getindex(c::Schedules, sigle::Symbol) = c.sigle[(sigle,)]

function Schedules(fas::String, med::String)
    fas_df = CSV.read(open(fas, enc"ISO-8859-1"), DataFrame, header=9, footerskip=7)
    med_df = CSV.read(open(med, enc"ISO-8859-1"), DataFrame, header=9, footerskip=7)
    df = vcat(fas_df, med_df)
    sigle = Symbol.(df[!, "Mat."] .* "_" .* df[!, "Num. rép."])
    c_df = DataFrame(sigle=sigle,
                     nom=df[!, "Titre"],
                     volet=df[!, "Volet"],
                     section=df[!, "Sect."],
                     statut=df[!, "Statut"],
                     session=df[!, "Session"],
                     jour=df[!, "Jour"],
                     de=df[!, "De"],
                     a=df[!, "A"],
                     du=df[!, "Du"],
                     au=df[!, "Au"],
                     spans=expand.(df[!, "De"], df[!, "A"], df[!, "Du"], df[!, "Au"], df[!, "Jour"]))

    sections_df = groupby(c_df, ["sigle", "section"])
    sigle_df = groupby(c_df, "sigle")
    sect = Dict{Symbol, Vector{String}}()
    for k in keys(sigle_df)
        subdf = sigle_df[k]
        sect[last(subdf.sigle)] = unique(subdf.section)
    end
    Schedules(c_df, sections_df, sigle_df, sect)
end
