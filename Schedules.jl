# using Revise
using CSV, StringEncodings, DataFrames

include("Span.jl")

struct Schedules
    df::DataFrame
    sections::GroupedDataFrame
    sigle::GroupedDataFrame
    sect::Dict{String, Vector{String}}
end

function Schedules(fas::String, med::String)
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
    Schedules(c_df, sections_df, sigle_df, sect)
end

Base.getindex(c::Schedules, sigle::String, section::String) = c.sections[(sigle, section)]
Base.getindex(c::Schedules, sigle::String) = c.sigle[(sigle,)]

const daytoid = Dict(
    "Lu" => Dates.Monday,
    "Ma" => Dates.Tuesday,
    "Me" => Dates.Wednesday,
    "Je" => Dates.Thursday,
    "Ve" => Dates.Friday,
    "Sa" => Dates.Saturday,
    "Di" => Dates.Sunday
)

function spans(c::Schedules, sigle::String)
    res = DataFrame(sigle=String[], section=String[], volet=String[], sp=Vector{Span}[])
    df = c.sigle[(sigle,)]
    
    for row in eachrow(c.sigle[(sigle,)])
        sp = expand(row.de, row.a, tonext(row.du, daytoid[row.jour], same=true), toprev(row.au, daytoid[row.jour], same=true), daytoid[row.jour])
        push!(res, (sigle, row.section, row.volet, sp))
    end
    return res
    gdf = combine(groupby(res, [:section, :volet]), :sp => vcat)
    gdf
end

# res = spans(c, "IFT 1015")