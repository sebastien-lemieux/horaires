# include("Schedule.jl")
# include("VolSec.jl")
include("Program.jl")
include("Schedules.jl")

p_blocs, p_courses = Program("https://admission.umontreal.ca/programmes/baccalaureat-en-bio-informatique/structure-du-programme/")
schedules = Schedules("A2024_FAS.csv", "A2024_FMed.csv")


## To fix

function checkConflict(sigle_a, sigle_b)
    alt = schedules(c, sigle_a)
    alt_b = schedules(c, sigle_b)
    comp = compatible(alt, alt_b)
    println("Sections compatibles:")
    println(join(comp, "\n"))

    println("\nSections en conflit:")
    conf = conflict(alt, alt_b)
    println(join(conf, "\n"))
end

# checkConflict("IFT 1015", "BIN 1002")
checkConflict("IFT 1015", "BCM 2550")
# c["BCM 2550"]
# c["IFT 1015", "A"]

session_1 = ["IFT 1015", "BCM 1501", "BIN 1002", "BCM 2550", "IFT 1215"]
# session_1 = ["IFT 1015", "BCM 1501", "BIN 1002", "BCM 2550", "MAT 1400"]

n = length(session_1)

for i=1:n, j=(i+1):n
    a, b = session_1[i], session_1[j]
    println("$a vs. $b\n")
    checkConflict(a, b)
end

sigle_a, sigle_b = "IFT 1015", "BIN 1002"
alt = schedules(c, sigle_a)
alt_b = schedules(c, sigle_b)
comp = compatible(alt, alt_b)
conf = conflict(alt, alt_b)

s_a = alt[["A", "A101"]]
s_b = alt_b[["A", "A1"]]

conflict(s_a, s_b)