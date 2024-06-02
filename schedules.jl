include("Schedule.jl")
include("VolSec.jl")

c = Courses("A2024_FAS.csv", "A2024_FMed.csv")

function checkConflict(sigle_a, sigle_b)
    alt = schedules(c, sigle_a)
    alt_b = schedules(c, sigle_b)
    comp = compatible(alt, alt_b)
    if isempty(comp)
        println("Aucune sections compatibles:")
        conf = conflict(alt, alt_b)
        println(join(conf, "\n"))
    else
        println("Sections compatibles:")
        println(join(comp, "\n"))
    end
end

checkConflict("IFT 1015", "BIN 1002")
checkConflict("IFT 1015", "MAT 1400")

