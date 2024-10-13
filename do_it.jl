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

model = Model(Gurobi.Optimizer)
avail_sections.var = @variable(model, sec_var[i=1:nrow(avail_sections)], Bin)

# unique section per course
gdf = groupby(avail_sections, :sigle)
sec_cst = Dict{Symbol, Any}()
for sdf in gdf
    nrow(sdf) < 2 && continue
    @constraint(model, sum(sdf.var) ≤ 1)
end




@objective(model, Max, sum(sec_var))
optimize!(model)
# courses(model, prog)


# generateLHS!(prog, course_j, var)



# include("Exigences.jl")
# str = DataFrame(r[:id, :IFT1025]).requirement_text[1]

# course_j = Dict(:IFT1015 => 1, :IFT1016 => 2)
# generateLHS(str, course_j, :blip)