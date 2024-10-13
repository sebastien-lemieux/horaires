prog = p["Baccalauréat en bio-informatique (B. Sc.)"]
# prog = p[Symbol("146811")]
# courses = getcourses(prog)

# id = r[prog].id # Returns 

# for (i, sym) in enumerate(unique(id))
#     println(i, ", ", sym)
# end

# a = s[:semester, :A24]
# b = a & s[:sigle, :IFT1015] & s[:msection, :A]
# c = a & s[:sigle, :BIN1002]
# # c = s[:msection, :A]
# bcm = s[:sigle, :BCM1521] & a


# conflict_expl(vcat(b[:span]...), vcat(c[:span]...))

# span1 = sort(vcat(b[:span]...))
# span2 = sort(vcat(c[:span]...))

# if _conflict(span1, span2)
#     xpl = conflict_expl(span1, span2)
#     for x in xpl
#         cfl = s.df[x, [:sigle, :section, :volet, :teachers, :semester, :jour, :time_s, :time_e]]
#         println(cfl)
#         println(Dates.format(maximum(cfl.time_s), "HH:MM"), "-", Dates.format(minimum(cfl.time_e), "HH:MM"))
#     end
# end

### First attempt Optimizer

# section_v = Section[]
# course_j = Dict{Symbol, Int}()
# for (j, sym) in enumerate(course_list)
#     course_j[sym] = j
#     sections = prepSections(schedules, prog, sym)
#     for sec in sections
#         push!(section_v, sec)
#     end
# end

# done = Symbol[:IFT_1065, :IFT_1016, :BCM_2550, :BIN_1002, :BCM_1501]

# @variable(model, sec_var[i=1:length(section_v)])
# @variable(model, done_var[i=1:length(course_list)])

# ## Can't take a course already taken
# for (i, sec) in enumerate(section_v)
#     j = course_j(sec.sigle)
#     @constraint(model, sec_var[i] + done_var[j] ≤ 2)
# end

# ## Req must be Met
# str = "IFT2015 ET (MAT1978 OU MAT1720 OU BIG9999)"
# generateLHS(str, course_j, :done_var)
# for sec in section_v
#     lhs = eval(generateLHS(str, course_j, :done_var))
#     @constraint(model, lhs ≥ 1)
# end

# ## No section in conflict
# for i=1:length(section_v), j=(i+1):length(section_v)
#     if conflict(section_v[i].spans, section_v[j].spans)
#         println("Conflict: $(section_v[i]) with $(section_v[j])")
#         @constraint(model, sec_var[i] + sec_var[j] ≤ 1)
#     end
# end

# ## No more than 15 credits per session
# @constraint(model, sum(sec_var[i] * section_v[i].credit for i in eachindex(section_v)) ≤ 15)

# ## Maximize the number of credit
# @objective(model, Max, sum(sec_var[i] * section_v[i].credit for i=eachindex(section_v)))

# optimize!(model)

# section_v[value.(sec_var) .== 1.0] ## Show results

