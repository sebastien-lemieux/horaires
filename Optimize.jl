module Optimize

using JuMP, Gurobi
using DataFrames

using ..Programs, ..Repertoires, ..Schedules, ..MData

export ChemOpt_1

# Cheminement optimizer
struct ChemOpt_1
    data::Data
    courses::DataFrame
    semester_schedules::Vector{Symbol}
    decision::DataFrame
end

nb_s(o::ChemOpt_1) = length(o.semester_schedules)
nb_d(o::ChemOpt_1) = nrow(o.decision)
nb_c(o::ChemOpt_1) = nrow(o.courses)

function doneby!(model, sigle, semester)
    tmp_id = findfirst(sigle .== courses.sigle)
    tmp_done_before = model[:done_before][tmp_id, semester]
    tmp_doing = model[:doing][tmp_id, semester]
    @constraint(model, tmp_done_before + tmp_doing ≥ 1)
end

function conflictissues!(active_conflict, decision, s::ScheduleCollection)
    active_conflict.v_issue .= value.(active_conflict.var) .≤ 0

    for issue in eachrow(active_conflict[active_conflict.v_issue,:])
        a_span = getspan(decision, issue.sigle_a, issue.msection_a, issue.schedule)
        b_span = getspan(decision, issue.sigle_b, issue.msection_b, issue.schedule)
        for (sa, sb) in conflict_expl(a_span, b_span)
            function __string(i)
                row = s.df[i.s_id, [:sigle, :msection, :volet, :semester]]
                return "$(i.s_id)-$(row.sigle)($(row.msection)):$(row.volet)"
            end
            date_str = Dates.format(sb.s, "yyyy-mm-dd HH:MM")
            println("$date_str:  $(__string(sa)) with $(__string(sb))")

        end

    end
end

function reportblocs!(active_bloc)
    active_bloc.v_min = value.(active_bloc.min)
    active_bloc.v_max = value.(active_bloc.max)
    active_bloc.v_credits = value.(active_bloc.credits)
    active_bloc.b_min = [b.min for b in active_bloc.bloc]
    active_bloc.b_max = [b.max for b in active_bloc.bloc]
    active_bloc.id = [b.id for b in active_bloc.bloc]
    active_bloc.name = [b.name for b in active_bloc.bloc]
    active_bloc[:,[:id, :name, :b_min, :b_max, :v_credits]]
end

function preferences_template(courses, fn)
    f = open(fn, "w")
    o = sortperm(courses.sigle)
    for i in o
        println(f, "$(courses[i, "sigle"]) 1.0")
    end
    close(f)
end

function done!(courses, fn::String)
    f = open(fn, "r")
    for line in readlines(f)
        c = strip(line)
        courses[courses.sigle .== Symbol(c), :before] .= 1
        # println(courses[courses.sigle .== Symbol(c), :])
    end
end

function ChemOpt_1(data::Data, prog_str::String,
                   semester_schedules::Vector{Symbol} = [:A25, :H26, :A25, :H26, :A25, :H26],
                   pref_fn::Union{String, Nothing} = nothing,
                   done_fn::Union{String, Nothing} = nothing)
    courses = getcourses(data.p[prog_str])
    courses.credits .= data.r[courses.sigle].credits
    courses.req .= data.r[courses.sigle].requirement_text
    courses.before .= 0
    courses.pref .= 1.0

    pref_fn ≠ nothing && preferences!(courses, pref_fn)
    done_fn ≠ nothing && done!(courses, done_fn)

    semester_schedules
    nb_s = length(semester_schedules)

    ## Prepare decision matrix (to take a section i at semester j)

    avail = DataFrame(data.s[row -> row.sigle ∈ courses.sigle])
    decision = combine(groupby(avail, [:sigle, :msection, :semester])) do df
        (; span = [reduce(vcat, df.span)])
    end

    decision.credits = data.r[decision.sigle].credits

    return ChemOpt_1(prs, courses, semester_schedules, decision)
end

end