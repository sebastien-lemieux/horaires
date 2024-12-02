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

function doneby!(model, sigle, semester)
    tmp_id = findfirst(sigle .== courses.sigle)
    tmp_done_before = model[:done_before][tmp_id, semester]
    tmp_doing = model[:doing][tmp_id, semester]
    @constraint(model, tmp_done_before + tmp_doing ≥ 1)
end

function showsolution(model, semester_schedules, decision)
    choices = round.(Bool, value.(model[:decision_var]))
    for k=1:nb_s
        println("Session $k ($(semester_schedules[k]))")
        for i=1:nb_d
            choices[i,k] && println("  $i: $(decision[i, :sigle]):$(decision[i, :msection])")
        end
    end
end

function getspan(decision, sigle, msection, semester)
    subset = (decision.sigle .== sigle .&& decision.msection .== msection .&& decision.semester .== semester)
    res = decision[subset,:span]
    return res[1]
end

function conflictissues!(active_conflict, decision, s::Schedules)
    active_conflict.v_issue .= value.(active_conflict.var) .≤ 0

    for issue in eachrow(active_conflict[active_conflict.v_issue,:])
        a_span = getspan(decision, issue.sigle_a, issue.msection_a, issue.schedule)
        b_span = getspan(decision, issue.sigle_b, issue.msection_b, issue.schedule)
        for (sa, sb) in conflict_expl(a_span, b_span)
            function __string(i)
                row = s.df[i.s_id, [:sigle, :name, :msection, :volet, :semester]]
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