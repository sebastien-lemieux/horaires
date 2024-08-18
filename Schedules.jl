using DataFrames, HTTP, JSON, JLD2

include("Span.jl")

struct Schedules
    df::DataFrame
    # sections::GroupedDataFrame
    # sigle::GroupedDataFrame
    # sec_d::Dict{Symbol, Vector{Symbol}}
end

# A specific course at a given session
# url = "https://planifium-api.onrender.com/api/v1/schedules?courses_list=['IFT1015']&min_semester=A24"
if isfile("schedules.jld2")
    crs = load("schedules.jld2", "crs")
else
    url = "https://planifium-api.onrender.com/api/v1/schedules"
    rsp = HTTP.get(url)
    # write("bioinfo.json", String(rsp.body))
    @assert(rsp.status == 200)
    crs = JSON.parse(String(rsp.body))
    save("schedules.jld2", Dict("crs" => crs))
end;


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

as = _addtorow!(crs)

select!(as, :, :sigle => ByRow(Symbol) => :sigle)
select!(as, :, :name => ByRow(Symbol) => :name)
select!(as, :, :_id => ByRow(Symbol) => :id, copycols=false)
select!(as, :, :sections_name => ByRow(Symbol) => :section)
select!(as, :, :inscription => ByRow(identity) => :inscription)
# select!(as, :, :sections_volets_activities_start_time => ByRow(Symbol) => :start_time)
# select!(as, :, :sections_volets_activities_end_time => ByRow(Symbol) => :end_time)
select!(as, :, :sections_volets_activities_place => ByRow(Symbol) => :place)
select!(as, :, :sections_volets_activities_campus => ByRow(Symbol) => :campus)
select!(as, :, :sections_volets_activities_days => ByRow(Symbol) => :day)
# select!(as, :, :sections_volets_activities_start_date => ByRow(Symbol) => :start_date)
# select!(as, :, :sections_volets_activities_end_date => ByRow(Symbol) => :end_date)
select!(as, :, :sections_volets_activities_pavillon_name => ByRow(Symbol) => :pavillon_name)
select!(as, :, :sections_volets_activities_mode => ByRow(Symbol) => :mode)
select!(as, :, :sections_volets_activities_room => ByRow(Symbol) => :room)
select!(as, :, :sections_volets_name => ByRow(Symbol) => :volet)
select!(as, :, :sections_teachers => ByRow(Symbol) => :teachers)
select!(as, :, :sections_capacity => ByRow(identity) => :capacity)
select!(as, :, :semester => ByRow(Symbol) => :semester)
select!(as, :, :fetch_date => ByRow(Date) => :fetch_date)
# select!(as, :, :semester_int => ByRow(Symbol) => :semester_int)
select!(as, :, :id => ByRow(Symbol) => :id)
select!(as, :, :jour => ByRow(Symbol) => :jour)

col_needed = [
    :sections_volets_activities_start_time,
    :sections_volets_activities_end_time,
    :sections_volets_activities_start_date,
    :sections_volets_activities_end_date,
    :sections_volets_activities_days
]
select!(as, :, col_needed => ByRow(expand) => :span)



# df = DataFrame()
# row_df = DataFrame()
# [c["sigle"] == "IFT1025" for c in crs] |> findfirst
# _addtorow!(row_df, crs[530])
# tmp = JSON.parse("""
# [{
#     "id": 23,
#     "name": "bingo",
#     "vec": [{"name": 12, "id": [1, 2, 3]}, {"name": 45, "id": [1, 2, 3]}]
# },
# {
#     "id": 24,
#     "name": "blop",
#     "vec": [{"name": 12, "id": [1, 2, 3]}]
# }]
# """)

# function Schedule(crs::Vector{Any})
#     df = DataFrame(sigle=Symbol[], name=String[], semester=Symbol[])
#     row = Any[]
#     for course in crs
#         row_c = vcat(row, Symbol(course["sigle"]), course["name"], Symbol(course["semester"]))
#         for section in course["sections"]
#             row_cs = vcat(row_c, section["teacher"])
#         end
#         push!(df, row_c)
#     end
#     df
# end

# df = Schedule(crs)

########
