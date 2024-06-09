using JuMP
using GLPK

# include("Schedule.jl")
# include("VolSec.jl")
include("Program.jl")
include("Schedules.jl")
include("Section.jl")

prog = Program("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/")
schedules = Schedules("A2024_FAS.csv", "A2024_FMed.csv")

course_list = [:IFT_1015, :BIN_1002, :BCM_1501, :BCM_2550, :IFT_1215, :MAT_1400]

model = Model(GLPK.Optimizer)

section_v = Section1[]
for sym in course_list
    sections = prepSections(schedules, prog, sym)
    for sec in sections
        push!(section_v, sec)
    end
end

@variable(model, sec_var[i=1:length(section_v)], Bin)

for i=eachindex(section_v)
    @constraint(model, sum(sec_var[i] * section_v[i].credit) ≤ 15)
end

for i=1:length(section_v), j=(i+1):length(section_v)
    if conflict(section_v[i].spans, section_v[j].spans)
        println("Conflict: $(section_v[i]) with $(section_v[j])")
        @constraint(model, sec_var[i] + sec_var[j] ≤ 1)
    end
end

@objective(model, Max, sum(sec_var[i] * section_v[i].credit for i=eachindex(section_v)))

optimize!(model)

section_v[value.(sec_var) .== 1.0]
