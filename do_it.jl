using JLD2

include("Program.jl");
include("Repertoire.jl");
include("Schedules.jl");

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

using JuMP, Gurobi
include("Exigences.jl");

prog = p["Baccalauréat en bio-informatique (B. Sc.)"]
semester = :A24
done = Symbol[]

# create sections variable
id = r[prog].id 

avail = s[row -> (row.sigle ∈ id && row.sigle ∉ done && row.semester == semester && length(row.span) ≥ 1)] |> DataFrame
avail_sections = combine(groupby(avail, [:sigle, :msection])) do df
    (; span = [reduce(vcat, df.span)])
end

avail_sections.credits = r[avail_sections.sigle].credits
avail_sections.req = r[avail_sections.sigle].requirement_text
avail_sections[!,:pref] .= 1.0

## prefs
obl = vcat([b.courses for b in prog.segments[1].blocs]...)
transform!(avail_sections, [:sigle, :pref] => ByRow((s,p) -> (s ∈ obl) ? 5.0 : p) => :pref)

## build model
model = Model(Gurobi.Optimizer)
avail_sections.var = @variable(model, sec_var[i=1:nrow(avail_sections)] ≥ 0, Bin)

# unique section per course
gdf = groupby(avail_sections, :sigle)
sec_cst = Dict{Symbol, Any}()
for sdf in gdf
    nrow(sdf) < 2 && continue
    @constraint(model, sum(sdf.var) ≤ 1)
end

# schedule conflicts
for i in 1:nrow(avail_sections)
    for j in (i+1):nrow(avail_sections)
        if _conflict(avail_sections[i, :span], avail_sections[j, :span])
            @constraint(model, avail_sections[i, :var] + avail_sections[j, :var] ≤ 1)
        end
    end
end

# max credits
@constraint(model, sum(avail_sections[:,:var] .* avail_sections[:,:credits]) ≤ 16)





@objective(model, Max, sum(sec_var .* avail_sections[:,:pref]))

set_optimizer_attribute(model, "PoolSearchMode", 2)  # Search for multiple solutions
set_optimizer_attribute(model, "PoolSolutions", 10)  # Limit to 10 solutions
optimize!(model)
# courses(model, prog)

avail_sections[value.(sec_var; result=1) .== 1.0,:]

# generateLHS!(prog, course_j, var)



# include("Exigences.jl")
# str = DataFrame(r[:id, :IFT1025]).requirement_text[1]

# course_j = Dict(:IFT1015 => 1, :IFT1016 => 2)
# generateLHS(str, course_j, :blip)rebuild