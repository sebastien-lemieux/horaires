using JuMP
# using GLPK
using Gurobi # Blazing fast!
using JLD2

include("Program.jl")
include("Schedules.jl")
include("Section.jl")
include("Exigences.jl")

if isfile("data.jld2")
    prog, schedules, exigence_d = load("data.jld2", "prog", "schedules", "exigence_d")
else
    prog = Program("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/")
    schedules = Schedules("A2024_FAS.csv", "A2024_FMed.csv")
    exigence_d = downloadExigences
    save("data.jld2", Dict("prog" => prog, "schedules" => schedules, "exigence_d" => exigence_d))
end

course_list = prog.courses.sigle ∩ schedules.df.sigle

model = Model(Gurobi.Optimizer)

section_v = Section[]
for sym in course_list
    sections = prepSections(schedules, prog, sym)
    for sec in sections
        push!(section_v, sec)
    end
end

@variable(model, sec_var[i=1:length(section_v)], Bin)

@constraint(model, sum(sec_var[i] * section_v[i].credit for i in eachindex(section_v)) ≤ 15)

for i=1:length(section_v), j=(i+1):length(section_v)
    if conflict(section_v[i].spans, section_v[j].spans)
        println("Conflict: $(section_v[i]) with $(section_v[j])")
        @constraint(model, sec_var[i] + sec_var[j] ≤ 1)
    end
end

@objective(model, Max, sum(sec_var[i] * section_v[i].credit for i=eachindex(section_v)))

optimize!(model)

section_v[value.(sec_var) .== 1.0]





