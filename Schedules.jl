using DataFrames, HTTP, JSON, JLD2

# struct Schedules end

include("Span.jl")
include("Mask.jl")

@maskable struct Schedules
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

## Get from URL

function Schedules(url::String)
    println("Loading from API...")
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)

    println("Parsing JSON to Julia...")
    crs = JSON.parse(String(rsp.body))

    println("Building Schedules table...")
    df = _addtorow!(crs)
    # return df
    fixSched!(df)
    schedules = Schedules(df)

    println("Done.")
    return schedules
end

## Utilities

function _backtrack(ch::Channel, s::Schedules, course_v, chosen=Vector{Span}(), sec=Vector{Tuple{Symbol, Symbol}}())
    # Schedules must be semester-selected
    if isempty(course_v)
        ## got a selection!
        put!(ch, sec)
    else
        course = pop!(course_v)
        course_mask = s[:sigle, course]
        msec_v = course_mask[:msection] |> unique
        for msec in msec_v
            msec_mask = s[:msection, msec] & course_mask
            msec_span = vcat(msec_mask[:span]...)
            if !_conflict(chosen, msec_span)
                _backtrack(ch, s, course_v, vcat(chosen, msec_span), [sec..., (course, msec)])
            end

        end
    end
end

function backtrack(s::Schedules, course_v::Vector{Symbol})
    Channel(1) do ch
        _backtrack(ch, s, course_v)
    end
end

sol = backtrack(s, [:IFT1015])

for s in sol
    println(s)
end
# s_sem.df[[s.s_id for s in vcat(sol...)] |> unique, :]

# function conflict_exp(s::Schedules, a::Mask{Schedules}, b::Mask{Schedules})
#     span1 = vcat(s[a].span...)
#     span2 = vcat(s[a].span...)

#     if _conflict(span1, span2)
#         xpl = conflict_expl(span1, span2)
#         for x in xpl
#             cfl = s.df[x, [:sigle, :section, :volet, :teachers, :semester, :jour, :time_s, :time_e]]
#             println(cfl)
#             println(Dates.format(maximum(cfl.time_s), "HH:MM"), "-", Dates.format(minimum(cfl.time_e), "HH:MM"))
#         end
#     end

# end