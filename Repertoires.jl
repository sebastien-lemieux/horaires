module Repertoires

using JSON, HTTP, DataFrames
using ..Masks, ..Programs

export Repertoire

## Act as an index over all courses details (no schedules since not session-specific)
## No schedule here since it is not associated to a semester yet

struct Repertoire <: AbstractMaskable
    df::DataFrame
end

Repertoire(m::Mask{Repertoire}) = Repertoire(DataFrame(m))

function push_course!(df::DataFrame, crs::Dict{String, Any})
    course_data = Dict{Symbol, Any}()
    course_data[:id] = Symbol(crs["_id"])
    
    course_data[:name] = crs["name"]
    course_data[:description] = crs["description"]
    course_data[:requirement_text] = crs["requirement_text"]
    
    course_data[:credits] = crs["credits"]
    
    for (term, available) in crs["available_terms"]
        course_data[Symbol(term)] = available
    end
    
    for (period, available) in crs["available_periods"]
        course_data[Symbol(period)] = available
    end
    
    # Convert the prepared dictionary into a DataFrame row and push it to the existing DataFrame
    push!(df, course_data)
end

function Repertoire(url::String)
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)
    crs = JSON.parse(String(rsp.body))
    df = DataFrame(id=Symbol[], name=String[], description=String[], requirement_text=String[], credits=Float32[], winter=Bool[], summer=Bool[], autumn=Bool[], daytime=Bool[], evening=Bool[])
    for c in crs
        push_course!(df, c)
    end
    return Repertoire(df)
end

# Search on course id Symbol (ex. :IFT1015)
Base.getindex(r::Repertoire, sym::Symbol) = r.df[r.df.id .== sym, :]
Base.getindex(r::Repertoire, v::Vector{Symbol}) = vcat([r[sym] for sym in v]...)
Base.getindex(r::Repertoire, prog::Program) = r[getcourses(prog).sigle]

# Search with regex on course name (ex. r"programmation"i)
Base.getindex(r::Repertoire, regex::Regex) = r.df[.!isnothing.(match.(regex, r.df.name)), :]

credits(r::Repertoire, sym::Symbol) = r[sym][1, :credits]

end
