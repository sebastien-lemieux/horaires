using DataFrames, HTTP, JSON, JLD2

include("Span.jl")

struct Schedules
    df::DataFrame
end

# A specific course at a given session
# url = "https://planifium-api.onrender.com/api/v1/schedules?courses_list=['IFT1015']&min_semester=A24"
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
    select!(df, Not(:sections_number_inscription), :sections_number_inscription => ByRow(identity) => :inscription)
    select!(df, Not(:sections_volets_activities_place), :sections_volets_activities_place => ByRow(Symbol) => :place)
    select!(df, Not(:sections_volets_activities_campus), :sections_volets_activities_campus => ByRow(Symbol) => :campus)
    # select!(df, Not(:sections_volets_activities_days), :sections_volets_activities_days => ByRow(Symbol) => :day)
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
    # select!(df, :, :sections_volets_activities_start_time => ByRow(Symbol) => :start_time)
    # select!(df, :, :sections_volets_activities_end_time => ByRow(Symbol) => :end_time)
    # select!(df, :, :sections_volets_activities_start_date => ByRow(Symbol) => :start_date)
    # select!(df, :, :sections_volets_activities_end_date => ByRow(Symbol) => :end_date)
    # select!(df, :, :semester_int => ByRow(Symbol) => :semester_int)
    
    col_needed = [
        :sections_volets_activities_start_time,
        :sections_volets_activities_end_time,
        :sections_volets_activities_start_date,
        :sections_volets_activities_end_date,
        # :jour # this is converted to a Symbol already and still needed
    ]
    select!(df, Not(col_needed), [col_needed; :jour] => ByRow(expand) => :span)
end

## Get from URL

function Schedules(url::String)
    println("Loading from API...")
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)

    println("Parsing JSON to Julia...")
    crs = JSON.parse(String(rsp.body))

    println("Building Schedules table...")
    df = _addtorow!(crs)
    fixSched!(df)
    schedules = Schedules(df)

    println("Done.")
    return schedules
end



