module Optimizers

# using JuMP, Gurobi
using DataFrames

using .Programs

# Cheminement optimizer
struct ChemOpt_1
    prog::Program
    courses::DataFrame
    semester_schedules::Vector{Symbol}
    decision::DataFrame
end

nb_s(o::ChemOpt_1) = length(o.semester_schedules)
nb_d(o::ChemOpt_1) = nrow(o.decision)
nb_c(o::ChemOpt_1) = nrow(o.courses)

function preferences!(courses, fn::String)
    f = open(fn, "r")
    for line in readlines(f)
        c, pref = strip.(split(line))
        courses[courses.sigle .== Symbol(c), :pref] .= parse(Float32, pref)
        # println(courses[courses.sigle .== Symbol(c), :])
    end
end

function done!(courses, fn::String)
    f = open(fn, "r")
    for line in readlines(f)
        c = strip(line)
        courses[courses.sigle .== Symbol(c), :before] .= 1
        # println(courses[courses.sigle .== Symbol(c), :])
    end
end

function ChemOpt_1(prog::Program, semester_schedules::Vector{Symbol} = [:A25, :H26, :A25, :H26, :A25, :H26],
                 pref_fn::Union{String, Nothing} = nothing,
                 done_fn::Union{String, Nothing} = nothing)
    courses = getcourses(prog)
    courses.credits .= r[courses.sigle].credits
    courses.req .= r[courses.sigle].requirement_text
    courses.before .= 0
    courses.pref .= 1.0

    pref_fn ≠ nothing && preferences!(courses, pref_fn)
    done_fn ≠ nothing && done!(courses, done_fn)

    semester_schedules
    nb_s = length(semester_schedules)

    ## Prepare decision matrix (to take a section i at semester j)

    avail = DataFrame(s[row -> row.sigle ∈ courses.sigle])
    decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
        (; span = [reduce(vcat, df.span)])
    end

    decision.credits = r[decision.sigle].credits

    return ChemOpt_1(prog, courses, semester_schedules, decision)
end

end