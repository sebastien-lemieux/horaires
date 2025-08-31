module MData

using NamedArrays, JLD2

using ..Common
using ..Programs
using ..Repertoires
using ..Schedules

export Data, merge

struct Data
    p::ProgramCollection
    r::Repertoire
    s::ScheduleCollection
    # d::NamedMatrix{Int}
end

function Data(fn, horaire)
    if isfile(fn)
        p, r, s = load(fn, "p", "r", "s")
    else
        p = ProgramCollection("https://planifium-api.onrender.com/api/v1/programs", FromPlanifium)
        r = Repertoire("https://planifium-api.onrender.com/api/v1/courses")
        s = ScheduleCollection(readdir("data/$horaire"), FromSynchroCSV)
        
        save(fn, Dict("p" => p, "r" => r, "s" => s))
    end
    return Data(p, r, s)
end

Base.merge(d::Data, s::ScheduleCollection) = Data(d.p, d.r, merge(d.s, s))

end
