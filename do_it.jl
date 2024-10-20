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
courses.req .= r[courses.sigle].requirement_text
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
# decision.req = r[decision.sigle].requirement_text
nb_d = nrow(decision)
# Move check_req as constraint # decision = decision[check_req.(decision.req, Ref(done)),:]

nb_c = nrow(courses)
c2d = [decision[j, :sigle] == courses[i, :sigle] for i=1:nb_c, j=1:nb_d]
# before_v = [(courses[i] ∈ before) ? 1 : 0 for i in 1:nb_c, _=1:1]

## build_model
using JuMP, Gurobi
model = Model(Gurobi.Optimizer)
req = Reqs(model, courses);

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
                # @constraint(model, decision_var[i, k] + decision_var[j, k] ≤ 1)
            end
        end
    end
end

# max credits and prog. objective
@expression(model, done, sum(doing, dims=2))
@constraint(model, [k=1:nb_s], sum(decision_var[:,k] .* decision[:,:credits]) ≤ 15)
# @constraint(model, sum(done .* courses[:,:credits]) ≥ 90)

# blocs
for segment in prog.segments
    println("Working on segment $(segment.name)")
    for bloc in segment.blocs
        println("Working on bloc $(bloc.name)")
        i = [req.d[c] for c in bloc.courses]
        isempty(i) && continue
        println(i)
        println(sum(done[i]))
        println(bloc.min, ", ", bloc.max)
        # @constraint(model, bloc.min ≤ sum(done[i]) ≤ bloc.max)
    end
end


# prereq

@variable(model, done_before[1:nb_c, 1:nb_s], Bin)
for i in 1:nb_c, k in 1:nb_s  # Start k from 2 because for k=1, done_before[i, 1] = 0
    if k == 1
        @constraint(model, done_before[i, k] >= courses.before[i])
    else
        for j in 1:(k-1)
            @constraint(model, done_before[i, k] ≥ done_before[i, j])
        end
        @constraint(model, done_before[i, k] ≤ sum(done_before[i, 1:(k-1)]))
    end
end

for c = 1:nb_c
    expr = to_expr(req, c)
    isnothing(expr) && continue
    for k = 1:nb_s
        var = gen(req, expr, k)
        @constraint(model, doing[c, k] ≤ var)
    end
end

pref = reshape(courses.pref, :, 1)
@objective(model, Max, sum(doing .* courses[:,:pref]))

set_optimizer_attribute(model, "FeasRelaxBigM", 1e6)  # Large M for the relaxation
optimize!(model)

# vars = GRBgetvars(model) #  model.getVars()
# ?ubpen = [1.0]*model.numVars
# GRBfeasrelax(model, 1, false, vars, None, 1842, None, None)
# model.optimize()


choices = round.(Bool, value.(decision_var))
for k=1:nb_s
    println("Session $k ($(semester_schedules[k]))")
    for i=1:nb_c
        choices[i,k] || continue
        println("  $(courses[i, :sigle])")
    end
end