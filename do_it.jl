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
semester_schedules = [:A24, :H25, :E24, :A24, :H25, :E24, :A24, :H25, :E24]
# before = Symbol[]
before = [:BIO2043, :IFT1025, :BIN1002, :BCM1503, :BCM1502, :BCM2550, :BIO1153, :BIO1803, :IFT1005, :IFT1015, :IFT2255, :BCM1501]

## Prepare decisiontions
id = r[prog].id 
nb_s = length(semester_schedules)

function _can(row)
    row.sigle ∈ id || return false
    # row.sigle ∉ before || return false
    # length(row.span) ≥ 1 || return false
    return true
end

avail = DataFrame(s[_can])
decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
    (; span = [reduce(vcat, df.span)])
end

decision.credits = r[decision.sigle].credits
decision.req = r[decision.sigle].requirement_text
decision[!,:pref] .= 1.0
nb_d = nrow(decision)
# Move check_req as constraint # decision = decision[check_req.(decision.req, Ref(done)),:]

courses = unique(decision.sigle)
nb_c = length(courses)
c2d = [decision[j, :sigle] == courses[i] for i=1:nb_c, j=1:nb_d]
before_v = [(courses[i] ∈ before) ? 1 : 0 for i in 1:nb_c, _=1:1]

using JuMP, Gurobi
## build_model
model = Model(Gurobi.Optimizer)
@variable(model, decision_var[i=1:nb_d, j=1:nb_s] ≥ 0, Bin)

@expression(model, done, sum(c2d * decision_var, dims=2) + before_v)
@constraint(model, done[i] ≤ 1 for i=1:nb_c) # do the course only once, no matter the section done or before


# ## introduire @expression pour modeliser ce qui est fait avant chaque session
# @expression(model, before[1:nrow(decision), 1:length(semester_schedules)], before[i, j-1] + decision[i, j-1] for i=1:nrow(decision), j=1:length(semester_schedules))

# unique section per course
gdf = groupby(decision, :sigle)
for k in keys(gdf)
    sdf = gdf[k]
    the_max = (k.sigle ∈ before) ? 0 : 1
    nrow(sdf) < 2 && continue
    @constraint(model, sum(sdf.var) ≤ the_max)
end

# schedule conflicts
for i in 1:nrow(decision)
    for j in (i+1):nrow(decision)
        if _conflict(decision[i, :span], decision[j, :span])
            @constraint(model, decision[i, :var] + decision[j, :var] ≤ 1)
        end
    end
end

# max credits
@constraint(model, sum(decision[:,:var] .* decision[:,:credits]) ≤ 16)

@objective(model, Max, sum(decision_var .* decision[:,:pref] .* decision[:,:credits]))

set_optimizer_attribute(model, "PoolSearchMode", 2)  # Search for multiple solutions
set_optimizer_attribute(model, "PoolSolutions", 10)  # Limit to 10 solutions
optimize!(model)


# *******
model = Model(Gurobi.Optimizer)
@variable(model, decision[1:10, 1:15] ≥ 0, Bin)
#@expression(model, before[i=1:10, 1:15], 0)  # You can replace 0 with your constant input for each course

# Step 2: Define the remaining part of the 'before' matrix (j > 1)
@expression(model, before[i=0:10, j=1:15], (j == 1) ? 0 : (before[i, j-1] + decision[i, j-1]) for i=0:10, j=1:15)
