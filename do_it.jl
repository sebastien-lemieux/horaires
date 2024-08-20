# using JuMP
# using Gurobi # Much faster than GLPK
using JLD2

include("Program.jl");
include("Repertoire.jl");
include("Schedules.jl");

# include("Section.jl");
# include("Exigences.jl");

## Load or prepare data

if isfile("data.jld2")
    p, r, s = load("data.jld2", "p", "r", "s")
else
    p = Programs("https://planifium-api.onrender.com/api/v1/programs")
    r = Repertoire("https://planifium-api.onrender.com/api/v1/courses")
    s = Schedules("https://planifium-api.onrender.com/api/v1/schedules")

    save("data.jld2", Dict("p" => p, "r" => r, "s" => s))
end;

# Play with data here!

prog = p["Baccalauréat en bio-informatique (B. Sc.)"]
# prog = p[Symbol("146811")]
# courses = getcourses(prog)

id = r[prog].id # Returns 

for (i, sym) in enumerate(unique(id))
    println(i, ", ", sym)
end

join(unique(id), ", ") |> println

using DataStructures
tmp = counter([str[1:3] for str in String.(id)])

for (mat, n) in sort(collect(tmp), lt=(a, b) -> a.second > b.second)
    println(mat, ", ", n)
end


a = s[:semester, :A24]
b1 = s[:sigle, :IFT1015]
b2 = s[:sigle, :BIN1002]
c = s[:section, :B] | s[:section, :B101]

span1 = sort(vcat(s[a & b1 & c].span...))
span2 = sort(vcat(s[a & b2].span...))

conflict(span1, span2)

deja = [:BCM_1501, :BCM_2550, :BIN_1002, :BIO_1203]
session, annee = :A, 2024

function solution(s::Schedule, sigle_v)

end

function _solution(s::Schedule, section_v)

end


# ## Create and optimize model (WIP)

# # generateTestFunc!(prog)
# generateEq!(prog)
# new_done = Set([:IFT_1065, :IFT_1016, :BCM_2550, :BIN_1002, :BCM_1501, :IFT_1215, :IFT_2125, :MAT_1600, :MAT_1978, :IFT_1025])

# prog[:IFT_1025].req(new_done)
# ## Build optimization model

# course_list = prog.courses.sigle ∩ schedules.df.sigle

# model = Model(Gurobi.Optimizer)

# section_v = Section[]
# course_j = Dict{Symbol, Int}()
# for (j, sym) in enumerate(course_list)
#     course_j[sym] = j
#     sections = prepSections(schedules, prog, sym)
#     for sec in sections
#         push!(section_v, sec)
#     end
# end

# done = Symbol[:IFT_1065, :IFT_1016, :BCM_2550, :BIN_1002, :BCM_1501]

# @variable(model, sec_var[i=1:length(section_v)])
# @variable(model, done_var[i=1:length(course_list)])

# ## Can't take a course already taken
# for (i, sec) in enumerate(section_v)
#     j = course_j(sec.sigle)
#     @constraint(model, sec_var[i] + done_var[j] ≤ 2)
# end

# ## Req must be Met
# str = "IFT2015 ET (MAT1978 OU MAT1720 OU BIG9999)"
# generateLHS(str, course_j, :done_var)
# for sec in section_v
#     lhs = eval(generateLHS(str, course_j, :done_var))
#     @constraint(model, lhs ≥ 1)
# end

# ## No section in conflict
# for i=1:length(section_v), j=(i+1):length(section_v)
#     if conflict(section_v[i].spans, section_v[j].spans)
#         println("Conflict: $(section_v[i]) with $(section_v[j])")
#         @constraint(model, sec_var[i] + sec_var[j] ≤ 1)
#     end
# end

# ## No more than 15 credits per session
# @constraint(model, sum(sec_var[i] * section_v[i].credit for i in eachindex(section_v)) ≤ 15)

# ## Maximize the number of credit
# @objective(model, Max, sum(sec_var[i] * section_v[i].credit for i=eachindex(section_v)))

# optimize!(model)

# section_v[value.(sec_var) .== 1.0] ## Show results





