include("Common.jl")
include("Programs.jl")
include("Masks.jl")
include("Repertoires.jl")
include("Requirements.jl")
include("Spans.jl")
include("Schedules.jl")
include("MData.jl")
include("Optimize.jl")
include("utils.jl")
using .Masks, .Programs, .Repertoires, .Requirements, .Schedules, .Common, .Spans, .MData
using CSV, DataFrames, Dates

data = Data("data/data.jld2", "data/Horaires_20250829");

## Prepare optimization data

prog = data.p["Baccalauréat en bio-informatique (B. Sc.)"]

courses = getcourses(prog)
courses.credits .= data.r[courses.sigle].credits
courses.req .= data.r[courses.sigle].requirement_text

prefs = CSV.File("preferences.csv"; types=[Symbol, Int, Float32], strict=true) |> DataFrame
courses = innerjoin(courses, prefs, on=:sigle, matchmissing=:error, validate=(true, true))

semester_schedules = [:A25, :H26, :E26, :A25, :H26]
sem_penalty = [0, 0, -100, 0, -10]
nb_s = length(semester_schedules)

## decision:  (to take a section i at semester j)
## - This needs to be refined into (take section i, at semester j, in bloc k)
## - It also need to include a large number of 02Z courses!

avail = DataFrame(data.s[row -> row.sigle ∈ courses.sigle])
decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
    (; span = [reduce(vcat, df.span)])
end

decision.credits = data.r[decision.sigle].credits # For computing credits done (total + bloc)
decision.credits_eff = data.r[decision.sigle].credits # For computing work load
decision[decision.sigle .== :BIN3005, :credits_eff] .= 2

nb_d = nrow(decision)
nb_c = nrow(courses)

## build_model
using JuMP, Gurobi
model = Model(Gurobi.Optimizer)
@variable(model, decision_var[i=1:nb_d, j=1:nb_s] ≥ 0, Bin)

req = ReqCollection(model, courses);

c2d = [decision[j, :sigle] == courses[i, :sigle] for i=1:nb_c, j=1:nb_d]
@expression(model, doing, c2d * decision_var) # pool sections into courses
@expression(model, done_before[i=1:nb_c, k=1:nb_s], courses.before[i] + ((k > 1) ? sum(doing[i, 1:(k-1)]) : 0))

# schedule conflicts
active_conflict = DataFrame(sigle_a=Symbol[], msection_a=Symbol[], sigle_b=Symbol[], msection_b=Symbol[], imm_a=Symbol[], imm_b=Symbol[], semester=Int[], schedule=Symbol[], var=VariableRef[])
for k in 1:nb_s
    for i in 1:nb_d
        if decision[i, :semester] ≠ semester_schedules[k]
            fix(decision_var[i, k], 0; force=true) # restrict section choices to semester where they are given
            continue
        end
        for j in (i+1):nb_d
            decision[j, :semester] ≠ semester_schedules[k] && continue
            for sp_a ∈ decision[i, :span], sp_b ∈ decision[j, :span]
                d = getdist(data.s, sp_a.imm, sp_b.imm)
                if _conflict(sp_a, sp_b, d)
                    var = @variable(model, binary=true)
                    push!(active_conflict, (sigle_a=decision[i, :sigle], msection_a=decision[i, :msection],
                                            sigle_b=decision[j, :sigle], msection_b=decision[j, :msection],
                                            imm_a=sp_a.imm, imm_b=sp_b.imm,
                                            semester=k, schedule=semester_schedules[k], var))
                    @constraint(model, var --> {decision_var[i, k] + decision_var[j, k] ≤ 1})
                    break
                end
            end
        end
    end
end

# max credits and prog. objective
@expression(model, done , sum(doing, dims=2) .+ courses.before)
@constraint(model, [i=1:nb_c], done[i] ≤ 1)
@constraint(model, [k=1:nb_s], sum(decision_var[:,k] .* decision[:,:credits_eff]) ≤ 15) # 15)
# @constraint(model, [k=1:(nb_s-1)], sum(decision_var[:,k] .* decision[:,:credits]) ≥ 15)
@constraint(model, sum(done .* courses[:,:credits]) ≥ 89) # 90) # 
# @constraint(model, sum(done .* courses[:,:credits]) ≥ 29)
# @constraint(model, sum(done .* courses[:,:credits]) ≤ 91)

# blocs
# active_bloc = DataFrame(bloc=Bloc[], min=VariableRef[], max=VariableRef[], credits=AffExpr[])
# @expression(model, credits, done .* courses.credits)

bloc_name = [b.id for s in prog.segments for b in s.blocs]
bloc_ind = @variable(model, bloc_ind[1:length(bloc_name), 1:2], binary=true)
bloc_i = 1

for segment in prog.segments
    println("Working on segment $(segment.name)")
    for bloc in segment.blocs
        println("Working on bloc $(bloc.name)")
        i = [req.d[c] for c in bloc.courses]
        isempty(i) && continue
        println(i)
        println(sum(done[i]))
        println(bloc.min, ", ", bloc.max)
        # bloc_id = replace(String(bloc.id), ' ' => '_')
        # var_1 = @variable(model, binary=true, base_name="min_$bloc_id")
        # var_2 = @variable(model, binary=true, base_name="max_$bloc_id")
        # push!(active_bloc, (bloc=bloc, min=var_1, max=var_2, credits=sum(done[i] .* courses.credits[i])))
        @constraint(model, bloc_ind[bloc_i, 1] --> {sum(done[i] .* courses.credits[i]) ≥ bloc.min}) #var_1 --> {cr ≥ bloc.min})
        @constraint(model, bloc_ind[bloc_i, 2] --> {sum(done[i] .* courses.credits[i]) ≤ bloc.max}) #var_2 --> {cr ≤ bloc.max})
        bloc_i = bloc_i + 1
        # println(value(sum(done[i] .* courses.credits[i])))
    end
end


# prereq ## add indicator var

req_var = Matrix{Any}(nothing, nb_c, nb_s)
JuMP.value(x::Nothing) = 1.0
for c = 1:nb_c
    expr = Requirements.to_expr(req, c)
    isnothing(expr) && continue
    for k = 1:nb_s
        req_var[c, k] = Requirements.gen(req, expr, k)
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

# forced!(:BIN1002, 1)
# forced!(:IFT1015, 1)
# forced!(:BCM1501, 1)
# forced!(:IFT1065, 2)
# forced!(:IFT1025, 2)
# forced!(:BCM1503, 2)
# # doneby!(model, :IFT2015, 3)
# # doneby!(model, :BCM2550, 3)
# # doneby!(model, :BCM2003, 4)
# # doneby!(model, :BIN3002, 5)
# # doneby!(model, :BIN3005, 5)

forced!(:BIO3204, 1)
# forced!(:STT1700, 1)
# forced!(:IFT1025, 1)
forced!(:BCM2502, 1)

# Objective & optimization
# pref = reshape(courses.pref, :, 1)
big = -10000.0
@objective(model, Max, sum(doing .* courses[:,:pref])
                       + (big ÷ 5) * sum(1 .- active_conflict.var)
                       + big * sum(1 .- bloc_ind)
                       + sum([sum(decision_var[:,k] .* decision[:,:credits]) * sem_penalty[k] for k ∈ 1:nb_s])
                    #    + 50 * (90 - sum(done .* courses[:,:credits]))
                    #    + 5 * sum(done .* courses[:,:credits])
            )

## Basic ##

optimize!(model)

showsolution(model, semester_schedules, decision)
# inactivated_cst(active_conflict, active_bloc)
# conflictissues!(active_conflict, decision, s)

# # Report blocs
# reportblocs!(active_bloc)

## Explore ##

import MathOptInterface as MOI
MOI.Utilities.reset_optimizer(model)
feasible = true
solutions_found = 0
max_sol = 10
set_optimizer_attribute(model, "OutputFlag", 0)

while feasible && solutions_found < max_sol
    optimize!(model)
    term_status = termination_status(model)
    
    (term_status == MOI.INFEASIBLE || term_status == MOI.INFEASIBLE_OR_UNBOUNDED) && break
    if term_status == MOI.INFEASIBLE
        feasible = false
        break
    end

    solutions_found += 1
    println("\nSolution #$solutions_found --------------------\n")


    # Retrieve current solution values
    showsolution(model, semester_schedules, decision)

    # Build the 'exclusion constraint'
    # sum_{j : sol[j] == 1}(1 - x[j]) + sum_{j : sol[j] == 0}(x[j]) >= 1
    sol = value(decision_var)
    expr = @expression(model, sum((1 - decision_var[i, k]) for k=1:nb_s, i=1:nb_d if sol[i, k] ≈ 1) +
                                 sum(decision_var[i, k] for k=1:nb_s, i=1:nb_d if sol[i, k] ≈ 0))
    @constraint(model, expr ≥ 1)
end

# println("Total distinct solutions found: $solutions_found")
