using JLD2

include("Mask.jl");

include("Program.jl");
include("Repertoire.jl");
include("Span.jl");
include("Schedules.jl");
include("Exigences.jl");
include("utils.jl");

## Load or prepare data

if isfile("data.jld2")
    p, r, s = load("data.jld2", "p", "r", "s")
else
    p = Programs("https://planifium-api.onrender.com/api/v1/programs")
    r = Repertoire("https://planifium-api.onrender.com/api/v1/courses")
    s = Schedules("https://planifium-api.onrender.com/api/v1/schedules")
    
    save("data.jld2", Dict("p" => p, "r" => r, "s" => s))
end;

include("modifs.jl")

## Optimize

prog = p["Baccalauréat en bio-informatique (B. Sc.)"]

courses = getcourses(prog)
courses.credits .= r[courses.sigle].credits
courses.req .= r[courses.sigle].requirement_text
courses.before .= 0
courses.pref .= 1.0

preferences!(courses, "template.prefs")
done!(courses, "template.done")

# courses[courses.sigle .== :IFT3395, :pref] .= 10

semester_schedules = [:H25, :A24, :H25, :A24, :H25]
nb_s = length(semester_schedules)

## Prepare decisions matrix (to take a section i at a semester j)

avail = DataFrame(s[row -> row.sigle ∈ courses.sigle])
decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
    (; span = [reduce(vcat, df.span)])
end
# filter!(row -> isempty(row.span), decision)

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
@variable(model, decision_var[i=1:nb_d, j=1:nb_s] ≥ 0, Bin)

req = Reqs(model, courses);

@expression(model, doing, c2d * decision_var) # pool sections into courses
@expression(model, done_before[i=1:nb_c, k=1:nb_s], courses.before[i] + ((k > 1) ? sum(doing[i, 1:(k-1)]) : 0))
# @variable(model, done_before[1:nb_c, 1:nb_s], Bin)
# @constraint(model, [i=1:nb_c], done_before[i, 1] >= courses.before[i]) #+ courses[i,:before] ≤ 1) # Courses need to be done once at most

# for i in 1:nb_c, k in 2:nb_s
#     # for j in 1:(k-1)
#     #     @constraint(model, done_before[i, k] ≥ done_before[i, j])
#     # end
#     @constraint(model, [i=1:nb_c], done_before[i, k] >= done_before[i, k-1])
#     # @constraint(model, done_before[i, k] ≤ doing[i, k])
# end

# @constraint(model, [i=1:nb_c], sum(doing[i,:]) + courses[i,:before] ≤ 1) # Courses need to be done once at most

# schedule conflicts
active_conflict = DataFrame(sigle_a=Symbol[], msection_a=Symbol[], sigle_b=Symbol[], msection_b=Symbol[], semester=Int[], schedule=Symbol[], var=VariableRef[])
for k in 1:nb_s
    for i in 1:nb_d
        if decision[i, :semester] ≠ semester_schedules[k]
            fix(decision_var[i, k], 0; force=true) # restrict section choices to semester where they are given
            continue
        end
        for j in (i+1):nb_d
            decision[j, :semester] ≠ semester_schedules[k] && continue
            if _conflict(decision[i, :span], decision[j, :span])

                var = @variable(model, binary=true)
                push!(active_conflict, (sigle_a=decision[i, :sigle], msection_a=decision[i, :msection],
                                        sigle_b=decision[j, :sigle], msection_b=decision[j, :msection],
                                        semester=k, schedule=semester_schedules[k], var))
                @constraint(model, var --> {decision_var[i, k] + decision_var[j, k] ≤ 1})
            end
        end
    end
end

# max credits and prog. objective
@expression(model, done , sum(doing, dims=2) .+ courses.before)
@constraint(model, [i=1:nb_c], done[i] ≤ 1)
@constraint(model, [k=1:nb_s], sum(decision_var[:,k] .* decision[:,:credits]) ≤ 16)
@constraint(model, [k=1:(nb_s-1)], sum(decision_var[:,k] .* decision[:,:credits]) ≥ 12)
@constraint(model, sum(done .* courses[:,:credits]) ≥ 90)
# @constraint(model, sum(done .* courses[:,:credits]) ≤ 91)

# blocs
active_bloc = DataFrame(bloc=Bloc[], min=VariableRef[], max=VariableRef[], credits=AffExpr[])
# @expression(model, credits, done .* courses.credits)
for segment in prog.segments
    println("Working on segment $(segment.name)")
    for bloc in segment.blocs
        println("Working on bloc $(bloc.name)")
        i = [req.d[c] for c in bloc.courses]
        isempty(i) && continue
        println(i)
        println(sum(done[i]))
        println(bloc.min, ", ", bloc.max)
        var_1 = @variable(model, binary=true)
        var_2 = @variable(model, binary=true)
        push!(active_bloc, (bloc=bloc, min=var_1, max=var_2, credits=sum(done[i] .* courses.credits[i])))
        @constraint(model, var_1 --> {sum(done[i] .* courses.credits[i]) ≥ bloc.min}) #var_1 --> {cr ≥ bloc.min})
        @constraint(model, var_2 --> {sum(done[i] .* courses.credits[i]) ≤ bloc.max}) #var_2 --> {cr ≤ bloc.max})
        # println(value(sum(done[i] .* courses.credits[i])))
    end
end


# prereq

req_var = Matrix{Any}(nothing, nb_c, nb_s)
JuMP.value(x::Nothing) = 1.0
for c = 1:nb_c
    expr = to_expr(req, c)
    isnothing(expr) && continue
    for k = 1:nb_s
        req_var[c, k] = gen(req, expr, k)
        @constraint(model, doing[c, k] ≤ req_var[c, k])
    end
end

# Program structure preferences
# doneby!(model, :BIN1002, 1 + 1)
# doneby!(model, :IFT1015, 1 + 1)
# doneby!(model, :BCM1501, 1 + 1)
# doneby!(model, :IFT1065, 2 + 1)
# doneby!(model, :IFT1025, 2 + 1)
# doneby!(model, :BCM1503, 2 + 1)
# doneby!(model, :IFT2015, 3 + 1)
# doneby!(model, :BCM2550, 3 + 1)
# doneby!(model, :BCM2003, 4 + 1)
# doneby!(model, :BIN3002, 5 + 1)
# doneby!(model, :BIN3005, 5 + 1)

# Objective & optimization
pref = reshape(courses.pref, :, 1)
big = 1000.0
@objective(model, Max, sum(doing .* courses[:,:pref]) 
                       + big * sum(active_conflict.var)
                       + big * sum(active_bloc.min)
                       + big * sum(active_bloc.max)
                       + 50 * (90 - sum(done .* courses[:,:credits])))

optimize!(model)

showsolution(model, semester_schedules, decision)
conflictissues!(active_conflict, decision, s)

# Report blocs
reportblocs!(active_bloc)