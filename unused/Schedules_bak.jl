# using Revise
using CSV, StringEncodings, DataFrames

include("Span.jl")

struct Schedules
    df::DataFrame
    sections::GroupedDataFrame
    sigle::GroupedDataFrame
    sec_d::Dict{Symbol, Vector{Symbol}}
end

session_bool(session::Symbol) = [s == session for s in [:A, :H, :E]]

Base.getindex(c::Schedules, sigle::Symbol) = c.sigle[(sigle,)]
Base.getindex(c::Schedules, sec::Section) = subset(c[sec.sigle, sec.session, sec.year], :section => ByRow(x -> x ∈ sec.sec))

function Base.getindex(c::Schedules, sigle::Symbol, session::Symbol, year::Int)
    c.sections[(sigle, year, session_bool(session)...)]
end

function Schedules()
    csv_f = filter(fn -> endswith(fn, ".csv"), readdir("from_synchro", join=true))
    all_df = DataFrame()
    for f in csv_f
        println(f)
        df = CSV.read(open(f, enc"ISO-8859-1"), DataFrame, header=9, footerskip=7)
        sigle = Symbol.(df[!, "Mat."] .* "_" .* df[!, "Num. rép."])
        c_df = DataFrame(sigle=sigle,
                     nom=df[!, "Titre"],
                     volet=df[!, "Volet"],
                     section=df[!, "Sect."],
                     statut=df[!, "Statut"],
                     jour=df[!, "Jour"],
                     de=df[!, "De"],
                     a=df[!, "A"],
                     du=df[!, "Du"],
                     au=df[!, "Au"],
                     spans=expand.(df[!, "De"], df[!, "A"], df[!, "Du"], df[!, "Au"], df[!, "Jour"]))

        m = match(r"/(.)(....).*", f)
        c_df[!, :A] .= (m[1] == "A")
        c_df[!, :H] .= (m[1] == "H")
        c_df[!, :E] .= (m[1] == "E")
        c_df[!, :annee] .= parse(Int, m[2])

        all_df = vcat(all_df, c_df)
    end

    select!(all_df, :, :jour => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :jour)
    select!(all_df, :, :section => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :section)
    select!(all_df, :, :statut => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :statut)
    select!(all_df, :, :volet => ByRow(x -> ismissing(x) ? :missing : Symbol(x)) => :volet)

    sections_df = groupby(schedules.df, [:sigle, :annee, :A, :H, :E])
    sigle_df = groupby(all_df, :sigle)
    sect_d = Dict{Symbol, Vector{Symbol}}()
    for k in keys(sigle_df)
        subdf = sigle_df[k]
        sect_d[last(subdf.sigle)] = unique(subdf.section)
    end

    return Schedules(all_df, sections_df, sigle_df, sect_d)
end
