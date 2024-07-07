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

function Schedules()
    csv_f = filter(fn -> endswith(fn, ".csv"), readdir("from_synchro", join=true))
    all_df = DataFrame()
    for f in csv_f
        println(f)
        df = CSV.read(open(f, enc"ISO-8859-1"), DataFrame, header=9, footerskip=7)
        m = match(r"/(.)(....).*", f)
        println(m[1] == "A")
        df[!, :a] .= (m[1] == "A")
        df[!, :h] .= (m[1] == "H")
        df[!, :e] .= (m[1] == "E")
        df[!, :annee] .= parse(Int, m[2])

        all_df = vcat(all_df, df)
    end

    return all_df
end
s = Schedules()


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
    # Not tested vvv
    select!(schedules.df, :, :jour => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :jour)
    select!(schedules.df, :, :section => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :section)
    select!(schedules.df, :, :statut => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :statut)
    select!(schedules.df, :, :volet => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :volet)
                     

    # sections_df = groupby(c_df, ["sigle", "section"])
    # sigle_df = groupby(c_df, "sigle")
    sect = Dict{Symbol, Vector{String}}()
    for k in keys(sigle_df)
        subdf = sigle_df[k]
        sect[last(subdf.sigle)] = unique(subdf.section)
    end

    Schedules(c_df, sections_df, sigle_df, sect)
end
