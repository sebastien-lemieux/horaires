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
semester = :A24
done = Symbol[]
# done = [:BIO2043, :IFT1025, :BIN1002, :BCM1503, :BCM1502, :BCM2550, :BIO1153, :BIO1803, :IFT1005, :IFT1015, :IFT2255, :BCM1501]

avail_sections = prepare_opt(p, r, s, prog, semester, done)
model, sec_var = build_model(avail_sections, done)
for i in 1:result_count(model)
    println(avail_sections[value.(sec_var; result=i) .== 1.0,:])
end


