include("Span.jl")

struct Schedules
    df::DataFrame
    # sections::GroupedDataFrame
    # sigle::GroupedDataFrame
    # sec_d::Dict{Symbol, Vector{Symbol}}
end

# A specific course at a given session
url = "https://planifium-api.onrender.com/api/v1/schedules?courses_list=['IFT1015']&min_semester=A24"

rsp = HTTP.get(url)
# write("bioinfo.json", String(rsp.body))
@assert(rsp.status == 200)
crs = JSON.parse(String(rsp.body))

prog = get_program(p, 146811)

function collect_courses(prog::Program)
    lst = Symbol[]
    for seg in prog.segments
        for blk in seg.blocs
            lst = vcat(lst, blk.courses)
        end
    end
    return unique(lst)
end

collect_courses(prog)

for s in crs[1]["sections"]
    println(s["name"])
end