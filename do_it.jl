using JLD2

include("Mask.jl");

include("Program.jl");
include("Repertoire.jl");
include("Span.jl");
include("Schedules.jl");
include("Exigences.jl");

## Load or prepare data

if isfile("data.jld2")
    p, r, s = load("data.jld2", "p", "r", "s")
else
    p = Programs("https://planifium-api.onrender.com/api/v1/programs")
    r = Repertoire("https://planifium-api.onrender.com/api/v1/courses")
    s = Schedules("https://planifium-api.onrender.com/api/v1/schedules")
    
    save("data.jld2", Dict("p" => p, "r" => r, "s" => s))
end;

## Optimize

prog = p["Baccalauréat en bio-informatique (B. Sc.)"]


courses = getcourses(prog)
courses.credits .= r[courses.sigle].credits
courses.before .= 0
courses.pref .= 1.0

semester_schedules = [:A24, :H25, :A24, :H25, :A24, :H25]
nb_s = length(semester_schedules)

## Prepare decisions matrix (to take a section i at a semester j)

avail = DataFrame(s[row -> row.sigle ∈ courses.sigle])
decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
    (; span = [reduce(vcat, df.span)])
end
filter!(row -> !isempty(row.span), decision)

decision.credits = r[decision.sigle].credits
decision.req = r[decision.sigle].requirement_text
nb_d = nrow(decision)
# Move check_req as constraint # decision = decision[check_req.(decision.req, Ref(done)),:]

nb_c = nrow(courses)
c2d = [decision[j, :sigle] == courses[i, :sigle] for i=1:nb_c, j=1:nb_d]
# before_v = [(courses[i] ∈ before) ? 1 : 0 for i in 1:nb_c, _=1:1]

## build_model
using JuMP, Gurobi
model = Model(Gurobi.Optimizer)
@variable(model, decision_var[i=1:nb_d, j=1:nb_s] ≥ 0, Bin)

@expression(model, doing, c2d * decision_var) # pool sections into courses
@constraint(model, [i=1:nb_c], sum(doing[i,:]) + courses[i,:before] ≤ 1) # Courses need to be done once at most

# schedule conflicts
for k in nb_s
    for i in 1:nb_d
        if decision[i, :semester] ≠ semester_schedules[k]
            fix(decision_var[i, k], 0; force=true) # restrict section choices to semester where they are given
            continue
        end
        for j in (i+1):nb_d
            decision[j, :semester] ≠ semester_schedules[k] && continue
            if _conflict(decision[i, :span], decision[j, :span])
                @constraint(model, decision_var[i, k] + decision_var[j, k] ≤ 1)
            end
        end
    end
end

# max credits and prog. objective
@constraint(model, [k=1:nb_s], sum(decision_var[:,k] .* decision[:,:credits]) ≤ 15)
@constraint(model, sum(done .* courses[:,:credits]) ≥ 90)

# prereq
d = Dict([courses[i, :sigle] => i for i=1:nb_c])
@expression(model, done_before[i=1:nb_c, k=1:nb_s], courses.before[i] + (k==1 ? 0 : maximum(doing[i, 1:(k-1)]))) # pool sections into courses
@constraint(model, [i=1:nb_c, k=1:nb_s], doing[i,k] ≤ transform_req(to_eq, i, "doing", "done_before"))

pref = reshape(courses.pref, :, 1)
@objective(model, Max, sum(done .* courses[:,:pref]))

optimize!(model)

choices = round.(Bool, value.(decision_var))
for k=1:nb_s
    println("Session $k ($(semester_schedules[k]))")
    for i=1:nb_c
        choices[i,k] || continue
        println("  $(courses[i, :sigle])")
    end
end