module Schedules

using DataFrames, HTTP, JSON, JLD2, CSV, Dates
using ..Masks
using ..Common
using ..Spans

export ScheduleCollection, merge

# struct Schedules end

struct ScheduleCollection <: AbstractMaskable
    df::DataFrame
end

## Parsing JSON

function _addtorow!(d::Dict{String, Any}, row_df=DataFrame(), path=String[])
    for (k, v) in d
        row_df = _addtorow!(v, row_df, [path; k])
    end
    return row_df
end

function _addtorow!(v::Vector{Any}, row_df=DataFrame(), path=String[])::DataFrame
    res = DataFrame[]
    for (i, item) in enumerate(v)
        push!(res, _addtorow!(item, deepcopy(row_df), path))
    end
    if length(res) == 0
        # println("path=$path")
        if path == ["sections", "teachers"]
            row_df = _addtorow!("", row_df, path)
        end
        if path == ["sections", "volets", "activities", "days"]
            row_df = _addtorow!("", row_df, path)
        end
        return row_df
    else
        return vcat(res...)
    end
end

function _addtorow!(elem::Union{Real, AbstractString}, row_df=DataFrame(), path=String[])
    col_name = Symbol(join(path, "_"))
    # println("col_name: [$col_name] -> $elem")
    # println(row_df)
    if nrow(row_df) == 0
        setproperty!(row_df, col_name, [elem])
    else
        # setproperty!(row_df, col_name, [elem])  # [:, col_name] .= [elem]
        # setindex!(row_df, [elem], :, col_name)
        row_df[:, col_name] .= elem
    end
    return row_df
end

function fixSched!(df::DataFrame)
    select!(df, Not(:sigle), :sigle => ByRow(Symbol) => :sigle; )
    select!(df, Not(:name), :name => ByRow(Symbol) => :name)
    select!(df, Not(:_id), :_id => ByRow(Symbol) => :id)
    select!(df, Not(:sections_name), :sections_name => ByRow(Symbol) => :section)
    select!(df, :, :section => ByRow(s -> Symbol(String(s)[1])) => :msection)
    select!(df, Not(:sections_number_inscription), :sections_number_inscription => ByRow(identity) => :inscription)
    select!(df, Not(:sections_volets_activities_place), :sections_volets_activities_place => ByRow(Symbol) => :place)
    select!(df, Not(:sections_volets_activities_campus), :sections_volets_activities_campus => ByRow(Symbol) => :campus)
    select!(df, Not(:sections_volets_activities_pavillon_name), :sections_volets_activities_pavillon_name => ByRow(Symbol) => :pavillon_name)
    select!(df, Not(:sections_volets_activities_mode), :sections_volets_activities_mode => ByRow(Symbol) => :mode)
    select!(df, Not(:sections_volets_activities_room), :sections_volets_activities_room => ByRow(Symbol) => :room)
    select!(df, Not(:sections_volets_name), :sections_volets_name => ByRow(Symbol) => :volet)
    select!(df, Not(:sections_teachers), :sections_teachers => ByRow(Symbol) => :teachers)
    select!(df, Not(:sections_capacity), :sections_capacity => ByRow(identity) => :capacity)
    select!(df, Not(:semester), :semester => ByRow(Symbol) => :semester)
    select!(df, Not(:fetch_date), :fetch_date => ByRow(Date) => :fetch_date)
    select!(df, Not(:id), :id => ByRow(Symbol) => :id)
    select!(df, Not(:sections_volets_activities_days), :sections_volets_activities_days => ByRow(Symbol) => :jour)
    df.row_id = 1:nrow(df)
    
    col_needed = [
        :sections_volets_activities_start_date,
        :sections_volets_activities_end_date,
    ]
    select!(df, Not(col_needed), [:row_id; :sections_volets_activities_start_time;
                                           :sections_volets_activities_end_time; col_needed;
                                           :jour] => ByRow(expand) => :span)
    _Time(str::String) = (str == "") ? nothing : Time(str)
    select!(df, Not(:sections_volets_activities_start_time), :sections_volets_activities_start_time => ByRow(_Time) => :time_s)
    select!(df, Not(:sections_volets_activities_end_time), :sections_volets_activities_end_time => ByRow(_Time) => :time_e)
end

## Load from...

function ScheduleCollection(url::String, ::Type{FromPlanifium})
    println("Loading from API...")
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)

    println("Parsing JSON to Julia...")
    crs = JSON.parse(String(rsp.body))

    println("Building Schedules table...")
    df = _addtorow!(crs)
    # return df
    fixSched!(df)
    schedules = ScheduleCollection(df)

    println("Done.")
    return schedules
end

# s = Schedules("https://planifium-api.onrender.com/api/v1/schedules", FromPlanifium)


function ScheduleCollection(fn::String, ::Type{FromAcademicCSV})
    println("Loading from CSV...")

    raw = DataFrame(CSV.File(fn, types=String))
    subset!(raw, "Composante - État" => state -> (state .== "Activé"))
    subset!(raw, "Trame - Identifiant" => ByRow(trame -> (ismissing(trame) | (trame ≠ "2x2h\n2x2h"))))
    subset!(raw, "Heures de la rencontre - Jour" => ByRow(jour -> (!ismissing(jour))))
    
    function _semester(str::String)
        tmp = ['H', 'P', 'E', 'A']
        c = tmp[parse(Int, str[4])]
        return Symbol("$c$(str[2:3])")
    end
    
    df = DataFrame()
    df.sigle = Symbol.(raw."Cours - Identifiant")
    df.section = [Symbol(str) for str in raw."Composante - Identifiant"]
    df.msection = [Symbol(str[1]) for str in raw."Composante - Identifiant"]
    df.volet = [Symbol(str) for str in raw."Type de composante - Identifiant"]
    df.jour = [acatosyn[str] for str in raw."Heures de la rencontre - Jour"]
    df.semester = _semester.(raw."Trimestre - Identifiant")
    df.row_id = 1:nrow(df)
    df.span = expand.(df.row_id, raw."Heures de la rencontre - Heure de début", raw."Heures de la rencontre - Heure de fin",
                      raw."Dates et heures - Date de début", raw."Dates et heures - Date de fin", df.jour)
    
    # fixSched!(df)
    # schedules = Schedules(df)

    println("Done.")
    return ScheduleCollection(df)
end

function ScheduleCollection(fn_v::Vector{String}, ::Type{FromAcademicCSV})
    all_s = [ScheduleCollection(fn, FromAcademicCSV) for fn in fn_v]
    reduce(all_s) do a, b
        ScheduleCollection(vcat(a.df, b.df))
    end
end

function Base.merge(a::ScheduleCollection, b::ScheduleCollection)
    # a.df = copy(a.df)
    # b.df = copy(b.df)
    cols = names(a.df) ∩ names(b.df)
    overwrite_c = unique(b.df.sigle)
    merged_s = vcat(subset(a.df, :sigle => ByRow(s -> s ∉ overwrite_c))[!,cols], b.df[!,cols])
    merged_s.row_id = 1:nrow(merged_s)
    return ScheduleCollection(merged_s)
end

# s = Schedules("data/A25.csv", FromAcademicCSV)

end
