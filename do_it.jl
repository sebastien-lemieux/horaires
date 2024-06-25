using JuMP
using Gurobi # Much faster than GLPK
using JLD2

include("Program.jl");
include("Schedules.jl");
include("Section.jl");
include("Exigences.jl");
include("Repertoire.jl");

if isfile("repertoire.jld2")
    repertoire = load("repertoire.jld2", "repertoire")
else
    repertoire = parseRepertoire("from_synchro/2023_2024_Répertoire_cours_1er_cycle_web.pdf")
    save("repertoire.jld2", Dict("repertoire" => repertoire))
end

if isfile("data.jld2")
    prog, schedules = load("data.jld2", "prog", "schedules")
else
    prog = Program("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/")
    schedules = Schedules("from_synchro/A2024_FAS.csv", "from_synchro/A2024_FMed.csv")
    scrapeExigences!(prog)
    # ***** do it using the repertoire *****
    # generateTestFunc!(prog)
    save("data.jld2", Dict("prog" => prog, "schedules" => schedules))
end;


# generateTestFunc!(prog)
generateEq!(prog)
new_done = Set([:IFT_1065, :IFT_1016, :BCM_2550, :BIN_1002, :BCM_1501, :IFT_1215, :IFT_2125, :MAT_1600, :MAT_1978, :IFT_1025])

prog[:IFT_1025].req(new_done)
## Build optimization model

course_list = prog.courses.sigle ∩ schedules.df.sigle

model = Model(Gurobi.Optimizer)

section_v = Section[]
course_j = Dict{Symbol, Int}()
for (j, sym) in enumerate(course_list)
    course_j[sym] = j
    sections = prepSections(schedules, prog, sym)
    for sec in sections
        push!(section_v, sec)
    end
end

done = Symbol[:IFT_1065, :IFT_1016, :BCM_2550, :BIN_1002, :BCM_1501]

@variable(model, sec_var[i=1:length(section_v)])
@variable(model, done_var[i=1:length(course_list)])

## Can't take a course already taken
for (i, sec) in enumerate(section_v)
    j = course_j(sec.sigle)
    @constraint(model, sec_var[i] + done_var[j] ≤ 2)
end

## Req must be Met
str = "IFT2015 ET (MAT1978 OU MAT1720 OU BIG9999)"
generateLHS(str, course_j, :done_var)
for sec in section_v
    lhs = eval(generateLHS(str, course_j, :done_var))
    @constraint(model, lhs ≥ 1)
end

## No section in conflict
for i=1:length(section_v), j=(i+1):length(section_v)
    if conflict(section_v[i].spans, section_v[j].spans)
        println("Conflict: $(section_v[i]) with $(section_v[j])")
        @constraint(model, sec_var[i] + sec_var[j] ≤ 1)
    end
end

## No more than 15 credits per session
@constraint(model, sum(sec_var[i] * section_v[i].credit for i in eachindex(section_v)) ≤ 15)

## Maximize the number of credit
@objective(model, Max, sum(sec_var[i] * section_v[i].credit for i=eachindex(section_v)))

optimize!(model)

section_v[value.(sec_var) .== 1.0] ## Show results





