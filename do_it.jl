# using JLD2

include("Cheminements.jl")
using .Cheminements

include("utils.jl");

## Load or prepare data

ChemOpt_1(p["Baccalauréat en bio-informatique (B. Sc.)"])



if isfile("data.jld2")
    p, r, s = load("data.jld2", "p", "r", "s")
else
    p = ProgramCollection("https://planifium-api.onrender.com/api/v1/programs")
    r = Repertoire("https://planifium-api.onrender.com/api/v1/courses")
    s = Schedules("https://planifium-api.onrender.com/api/v1/schedules")
    
    save("data.jld2", Dict("p" => p, "r" => r, "s" => s))
end;

#Append to existing schedule (to get default schedule for courses out of program)
academic_s = Schedules(["data/A25.csv", "data/H26.csv"], FromAcademicCSV)
s = append!(s, academic_s)

include("modifs.jl");

## Optimize

include("Optimize.jl")

prog = p["Baccalauréat en bio-informatique (B. Sc.)"]

courses = getcourses(prog)
courses.credits .= r[courses.sigle].credits
courses.req .= r[courses.sigle].requirement_text
courses.before .= 0
courses.pref .= 1.0

preferences!(courses, "template.prefs")
done!(courses, "template.done")

semester_schedules = [:A25, :H26, :A25, :H26, :A25, :H26]
nb_s = length(semester_schedules)

## Prepare decision matrix (to take a section i at semester j)

avail = DataFrame(s[row -> row.sigle ∈ courses.sigle])
decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
    (; span = [reduce(vcat, df.span)])
end

decision.credits = r[decision.sigle].credits
nb_d = nrow(decision)
nb_c = nrow(courses)

## build_model
using JuMP, Gurobi
model = Model(Gurobi.Optimizer)
@variable(model, decision_var[i=1:nb_d, j=1:nb_s] ≥ 0, Bin)

req = Reqs(model, courses);

c2d = [decision[j, :sigle] == courses[i, :sigle] for i=1:nb_c, j=1:nb_d]
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
@constraint(model, [k=1:nb_s], sum(decision_var[:,k] .* decision[:,:credits]) ≤ 15)
@constraint(model, [k=1:(nb_s-1)], sum(decision_var[:,k] .* decision[:,:credits]) ≥ 15)
@constraint(model, sum(done .* courses[:,:credits]) ≥ 90)
# @constraint(model, sum(done .* courses[:,:credits]) ≥ 29)
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
function forced!(sigle, semester)
    tmp_id = findfirst(sigle .== courses.sigle)
    tmp_done_before = done_before[tmp_id, semester]
    tmp_doing = doing[tmp_id, semester]
    @constraint(model, tmp_doing + tmp_done_before ≥ 1)
end

forced!(:BIN1002, 1)
forced!(:IFT1015, 1)
forced!(:BCM1501, 1)
forced!(:IFT1065, 2)
forced!(:IFT1025, 2)
forced!(:BCM1503, 2)
# doneby!(model, :IFT2015, 3)
# doneby!(model, :BCM2550, 3)
# doneby!(model, :BCM2003, 4)
# doneby!(model, :BIN3002, 5)
# doneby!(model, :BIN3005, 5)

# Objective & optimization
pref = reshape(courses.pref, :, 1)
big = 1000.0
@objective(model, Max, sum(doing .* courses[:,:pref]) 
                       + big * sum(active_conflict.var)
                       + big * sum(active_bloc.min)
                       + big * sum(active_bloc.max)
                       + 50 * (90 - sum(done .* courses[:,:credits]))
            )

## Basic ##

# optimize!(model)

# showsolution(model, semester_schedules, decision)
# conflictissues!(active_conflict, decision, s)

# # Report blocs
# reportblocs!(active_bloc)

## Explore ##

feasible = true
solutions_found = 0
set_optimizer_attribute(model, "OutputFlag", 0)

while feasible
    optimize!(model)
    term_status = termination_status(model)
    
    (term_status == MOI.INFEASIBLE || term_status == MOI.INFEASIBLE_OR_UNBOUNDED) && break
    if term_status == MOI.INFEASIBLE
        feasible = false
        break
    end

    solutions_found += 1
    println("Found solution #$solutions_found:")

    # Retrieve current solution values
    sol = value.(decision_var)
    # println("x = ", sol)
    choices = String[]
    for i=1:nb_d
        sol[i,1] ≈ 1.0 && push!(choices, "$(decision[i, :sigle]):$(decision[i, :msection])")
    end
    println(join(sort(choices), ", "))

    # Build the 'exclusion constraint'
    # sum_{j : sol[j] == 1}(1 - x[j]) + sum_{j : sol[j] == 0}(x[j]) >= 1
    expr = @expression(model, sum((1 - decision_var[i, k]) for k=1:1, i=1:nb_d if sol[i, k] ≈ 1) +
                                 sum(decision_var[i, k] for k=1:1, i=1:nb_d if sol[i, k] ≈ 0))
    @constraint(model, expr ≥ 1)
end

println("Total distinct solutions found: $solutions_found")
