module Cheminements

using JLD2

include("Common.jl")
include("Programs.jl")
include("Masks.jl")
include("Repertoires.jl")
include("Requirements.jl")
include("Spans.jl")
include("Schedules.jl")
include("Optimize.jl")
include("utils.jl")
using .Masks, .Programs, .Repertoires, .Requirements, .Schedules, .Common, .Spans

export data, PRS
export ChemOpt_1

struct PRS
    p::ProgramCollection
    r::Repertoire
    s::ScheduleCollection
    # d::NamedMatrix{Int}
end

include("Optimize.jl")
using .Optimizers

function data()
    if isfile("data.jld2")
        p, r, s = load("data.jld2", "p", "r", "s")
    else
        p = ProgramCollection("https://planifium-api.onrender.com/api/v1/programs", FromPlanifium)
        r = Repertoire("https://planifium-api.onrender.com/api/v1/courses")
        s = ScheduleCollection("https://planifium-api.onrender.com/api/v1/schedules", FromPlanifium)
        
        save("data.jld2", Dict("p" => p, "r" => r, "s" => s))
    end
    return PRS(p, r, s)
end

end