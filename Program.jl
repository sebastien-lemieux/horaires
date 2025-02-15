using DataFrames, HTTP, JSON

struct Bloc
    name::String
    max::Int
    min::Int
    id::Symbol
    courses::Vector{Symbol}
end

function json_to_bloc(bloc_json)
    courses = Symbol.(bloc_json["courses"])
    Bloc(
        bloc_json["name"],
        round(Int, bloc_json["max"]),
        round(Int, bloc_json["min"]),
        Symbol(bloc_json["id"]),
        courses
    )
end

struct Segment
    name::String
    id::Symbol
    blocs::Vector{Bloc}
    description::String
end

function json_to_segment(segment_json)
    blocs = [json_to_bloc(bloc) for bloc in segment_json["blocs"]]
    Segment(
        segment_json["name"],
        Symbol(segment_json["id"]),
        blocs,
        segment_json["description"]
    )
end

struct Program
    name::String
    id::Symbol
    segments::Vector{Segment}
    structure::String # need to parse
end

function Program(program_json)
    segments = [json_to_segment(segment) for segment in program_json["segments"]]
    Program(
        program_json["name"],
        Symbol(program_json["_id"]),
        segments,
        program_json["structure"]
    )
end

struct Programs ## Turn into a Maskable (df for programs)
    progs::Vector{Program}
    id::Dict{Symbol, Int}
    name::Dict{String, Int}
end

struct FromPlanifium end
function Programs(url::String, ::Type{FromPlanifium})
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)
    prs = JSON.parse(String(rsp.body))["programs"]

    progs = Program[]
    id = Dict{Symbol, Int}()
    name = Dict{String, Int}()

    for prog_json in prs
        prog = Program(prog_json)
        push!(progs, prog)
        id[prog.id] = length(progs)
        name[prog.name] = length(progs)
    end

    return Programs(progs, id, name)
end

Base.getindex(p::Programs, index::Int) = p.progs[index]
Base.getindex(p::Programs, sym::Symbol) = p.progs[p.id[sym]]
Base.getindex(p::Programs, name::String) = p.progs[p.name[name]]
Base.getindex(p::Programs, r::Regex) = [p.progs[i] for (name, i) in p.name if !isnothing(match(r, name))]

function getcourses(p::Program)
    df = DataFrame(prog=Symbol[], segment=Symbol[], bloc=Symbol[], sigle=Symbol[])
    p_sym = p.id
    for segment in p.segments
        s_sym = segment.id
        for bloc in segment.blocs
            b_sym = bloc.id
            for course in bloc.courses
                push!(df, [p_sym, s_sym, b_sym, course])
            end
        end
    end
    return df
end

