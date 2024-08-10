using DataFrames, HTTP, JSON

function get_programs(url)
    rsp = HTTP.get(url)
    @assert(rsp.status == 200)
    typeof(rsp.body)
    prs = JSON.parse(String(rsp.body))
    return prs["programs"]
end

function get_program(progs, name)
    for prog in progs
        if prog["name"] == name
            return prog
        end
    end
    return nothing
end

# # url = "https://planifium-api.onrender.com/api/v1/programs"
# url = "https://planifium-api.onrender.com/api/v1/programs?programs_list=[\"146811\"]"
# # name = "Baccalauréat en bio-informatique (B. Sc.)"

# # progs = get_programs(url);
# # prog = get_program(progs, name);
# prog = get_programs(url)[1];

struct Bloc
    name::String
    max::Int
    min::Int
    id::Symbol
    # description::String # Not needed?
    # type::String # Not needed?
    courses::Vector{Symbol}
end

function json_to_bloc(bloc_json)
    courses = Symbol.(bloc_json["courses"])
    Bloc(
        bloc_json["name"],
        round(Int, bloc_json["max"]),
        round(Int, bloc_json["min"]),
        Symbol(bloc_json["id"]),
        # bloc_json["description"],
        # bloc_json["type"],
        courses
    )
end

# json_to_bloc(prog["segments"][1]["blocs"][1])

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

# json_to_segment(prog["segments"][1])

struct Program
    name::String
    id::Symbol
    segments::Vector{Segment}
    structure::String # need to parse
    # courses::Vector{Symbol}
end

function json_to_program(program_json)
    segments = [json_to_segment(segment) for segment in program_json["segments"]]
    Program(
        program_json["name"],
        Symbol(program_json["_id"]),
        segments,
        program_json["structure"]
    )
end

# p = json_to_program(prog)

# Still needed?
# Base.getindex(p::Program, sym::Symbol) = p.courses[findfirst(p.courses.sigle .== sym),:]
# sigle_sym(str) = Symbol(str[1:3] * '_' * str[4:end])
