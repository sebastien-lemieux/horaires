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

function get_programs(url)
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)
    prs = JSON.parse(String(rsp.body))["programs"]

    p = Dict{Symbol, Program}()

    for prog_json in prs
        prog = Program(prog_json)
        p[prog.id] = prog
    end

    return p
end

# p = get_programs(url)

